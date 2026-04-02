#!/usr/bin/env node

/**
 * iOS 记账应用 - 实时监控系统
 * 核心功能：实时监控代码变化，自动执行构建和分析，主动报告问题并提供修复建议
 * 
 * 监控触发：
 * 1. 文件变化监控（代码保存后实时触发）
 * 2. 定时监控（定期执行）
 * 3. 手动触发（命令行参数）
 * 
 * 监控范围：
 * 1. 编译错误（xcodebuild）
 * 2. 类型不匹配（Swift 类型系统）
 * 3. UI约束冲突（Auto Layout）
 * 4. 静态代码分析（SwiftLint/SwiftFormat）
 */

const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);
const chokidar = require('chokidar');
const notifier = require('node-notifier');

// 配置
const CONFIG = {
  project: {
    name: 'iOS记账应用',
    path: process.cwd(), // 默认当前目录
    scheme: '记账应用',
    target: 'iOS'
  },
  
  monitoring: {
    fileWatch: {
      enabled: true,
      extensions: ['.swift', '.xib', '.storyboard', '.plist'],
      debounceMs: 1000
    },
    
    scheduledChecks: {
      enabled: true,
      intervalMinutes: 30,
      runOnStartup: true
    },
    
    buildChecks: {
      cleanBuild: true,
      destination: 'platform=iOS Simulator',
      configuration: 'Debug'
    }
  },
  
  notifications: {
    immediateFor: ['COMPILE_ERROR', 'CRASH_RISK', 'TYPE_MISMATCH'],
    batchFor: ['WARNING', 'CODE_SMELL', 'UI_CONSTRAINT'],
    channels: ['console', 'desktop']
  }
};

// 错误类型定义
const ERROR_TYPES = {
  COMPILE_ERROR: '编译错误',
  TYPE_MISMATCH: '类型不匹配',
  UI_CONSTRAINT_CONFLICT: 'UI约束冲突',
  MEMORY_LEAK: '内存泄漏风险',
  PERFORMANCE_ISSUE: '性能问题',
  CODE_SMELL: '代码异味',
  WARNING: '警告'
};

class FileWatcher {
  constructor(projectPath, config) {
    this.projectPath = projectPath;
    this.config = config;
    this.watcher = null;
    this.changeCallbacks = [];
  }
  
  start() {
    if (!this.config.fileWatch.enabled) {
      console.log('📁 文件监控已禁用');
      return;
    }
    
    console.log(`📁 开始监控项目目录: ${this.projectPath}`);
    
    this.watcher = chokidar.watch(this.projectPath, {
      ignored: /(^|[\/\\])\../, // 忽略隐藏文件
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: {
        stabilityThreshold: this.config.fileWatch.debounceMs,
        pollInterval: 100
      },
      depth: 5
    });
    
    this.watcher.on('change', (filePath) => {
      const ext = path.extname(filePath);
      if (this.config.fileWatch.extensions.includes(ext)) {
        console.log(`📝 检测到文件变化: ${path.relative(this.projectPath, filePath)}`);
        
        // 触发所有回调
        this.changeCallbacks.forEach(callback => {
          callback(filePath);
        });
      }
    });
    
    this.watcher.on('error', (error) => {
      console.error(`❌ 文件监控错误: ${error.message}`);
    });
    
    console.log('✅ 文件监控已启动');
  }
  
  onFileChange(callback) {
    this.changeCallbacks.push(callback);
  }
  
  stop() {
    if (this.watcher) {
      this.watcher.close();
      console.log('🛑 文件监控已停止');
    }
  }
}

class BuildExecutor {
  constructor(projectPath, config) {
    this.projectPath = projectPath;
    this.config = config;
  }
  
  async runBuild() {
    console.log('🔨 开始执行构建...');
    
    const buildCommand = this.buildXcodebuildCommand();
    
    try {
      const startTime = Date.now();
      const { stdout, stderr } = await execPromise(buildCommand, {
        cwd: this.projectPath,
        maxBuffer: 10 * 1024 * 1024 // 10MB
      });
      
      const buildTime = Date.now() - startTime;
      
      const result = {
        success: true,
        buildTime,
        output: stdout,
        warnings: this.extractWarnings(stderr),
        errors: this.extractErrors(stderr),
        rawStderr: stderr
      };
      
      console.log(`✅ 构建成功 (${buildTime}ms)`);
      return result;
      
    } catch (error) {
      console.log(`❌ 构建失败: ${error.message}`);
      
      return {
        success: false,
        output: error.stdout || '',
        warnings: this.extractWarnings(error.stderr || ''),
        errors: this.extractErrors(error.stderr || ''),
        rawStderr: error.stderr || ''
      };
    }
  }
  
  buildXcodebuildCommand() {
    const parts = ['xcodebuild'];
    
    if (this.config.buildChecks.cleanBuild) {
      parts.push('clean');
    }
    
    parts.push('build');
    parts.push(`-scheme "${this.config.project.scheme}"`);
    parts.push(`-destination "${this.config.buildChecks.destination}"`);
    parts.push(`-configuration "${this.config.buildChecks.configuration}"`);
    parts.push('QUIET=YES'); // 减少输出
    
    return parts.join(' ');
  }
  
  extractErrors(output) {
    const errors = [];
    const lines = output.split('\n');
    
    for (const line of lines) {
      if (line.includes('error:')) {
        const error = this.parseErrorLine(line);
        if (error) {
          errors.push(error);
        }
      }
    }
    
    return errors;
  }
  
  parseErrorLine(line) {
    // 尝试解析错误行格式: /path/to/file.swift:10:15: error: message
    const errorRegex = /^(.*?\.swift):(\d+):(\d+):\s*error:\s*(.+)$/;
    const match = line.match(errorRegex);
    
    if (match) {
      return {
        type: 'COMPILE_ERROR',
        file: match[1],
        line: parseInt(match[2]),
        column: parseInt(match[3]),
        message: match[4],
        rawLine: line
      };
    }
    
    // 通用错误格式
    const genericErrorRegex = /error:\s*(.+)$/;
    const genericMatch = line.match(genericErrorRegex);
    
    if (genericMatch) {
      return {
        type: 'COMPILE_ERROR',
        file: '未知',
        line: 0,
        column: 0,
        message: genericMatch[1],
        rawLine: line
      };
    }
    
    return null;
  }
  
  extractWarnings(output) {
    const warnings = [];
    const lines = output.split('\n');
    
    for (const line of lines) {
      if (line.includes('warning:')) {
        const warning = this.parseWarningLine(line);
        if (warning) {
          warnings.push(warning);
        }
      }
    }
    
    return warnings;
  }
  
  parseWarningLine(line) {
    // 尝试解析警告行格式
    const warningRegex = /^(.*?\.swift):(\d+):(\d+):\s*warning:\s*(.+)$/;
    const match = line.match(warningRegex);
    
    if (match) {
      return {
        type: 'WARNING',
        file: match[1],
        line: parseInt(match[2]),
        column: parseInt(match[3]),
        message: match[4],
        rawLine: line
      };
    }
    
    // 通用警告格式
    const genericWarningRegex = /warning:\s*(.+)$/;
    const genericMatch = line.match(genericWarningRegex);
    
    if (genericMatch) {
      return {
        type: 'WARNING',
        file: '未知',
        line: 0,
        column: 0,
        message: genericMatch[1],
        rawLine: line
      };
    }
    
    return null;
  }
}

class StaticAnalyzer {
  constructor(projectPath) {
    this.projectPath = projectPath;
  }
  
  async runSwiftLint() {
    console.log('🔍 运行 SwiftLint 分析...');
    
    try {
      const { stdout } = await execPromise('swiftlint', {
        cwd: this.projectPath
      });
      
      return this.parseSwiftLintOutput(stdout);
    } catch (error) {
      // SwiftLint 返回非零退出码表示发现问题
      if (error.stdout) {
        return this.parseSwiftLintOutput(error.stdout);
      }
      console.log(`⚠️ SwiftLint 执行失败: ${error.message}`);
      return [];
    }
  }
  
  parseSwiftLintOutput(output) {
    const issues = [];
    const lines = output.split('\n');
    
    for (const line of lines) {
      if (line.includes('.swift:')) {
        const parts = line.split(':');
        if (parts.length >= 4) {
          const issue = {
            type: 'CODE_SMELL',
            file: parts[0],
            line: parseInt(parts[1]),
            column: parseInt(parts[2]),
            rule: parts[3].trim(),
            message: parts.slice(4).join(':').trim(),
            source: 'SwiftLint'
          };
          
          // 分类问题类型
          if (issue.rule.includes('type')) {
            issue.subtype = 'TYPE_RELATED';
          } else if (issue.rule.includes('performance')) {
            issue.subtype = 'PERFORMANCE_ISSUE';
          } else if (issue.rule.includes('memory')) {
            issue.subtype = 'MEMORY_LEAK';
          }
          
          issues.push(issue);
        }
      }
    }
    
    return issues;
  }
}

class FixSuggestionEngine {
  generateFixSuggestion(issue) {
    const suggestionGenerators = {
      'COMPILE_ERROR': this.generateCompileErrorFix.bind(this),
      'TYPE_MISMATCH': this.generateTypeMismatchFix.bind(this),
      'UI_CONSTRAINT_CONFLICT': this.generateUIConstraintFix.bind(this),
      'MEMORY_LEAK': this.generateMemoryLeakFix.bind(this),
      'CODE_SMELL': this.generateCodeSmellFix.bind(this),
      'WARNING': this.generateWarningFix.bind(this)
    };
    
    const generator = suggestionGenerators[issue.type] || this.generateGenericFix.bind(this);
    return generator(issue);
  }
  
  generateCompileErrorFix(issue) {
    const message = issue.message.toLowerCase();
    
    if (message.includes('cannot find')) {
      return {
        title: '未找到符号',
        description: issue.message,
        fixCode: this.suggestMissingImportOrDeclaration(issue),
        explanation: '可能是缺少导入语句或函数/变量未声明',
        severity: 'HIGH'
      };
    }
    
    if (message.includes('type') && message.includes('cannot convert')) {
      return {
        title: '类型转换错误',
        description: issue.message,
        fixCode: this.suggestTypeConversion(issue),
        explanation: 'Swift 需要显式类型转换，使用 as? 或 as! 进行转换',
        severity: 'MEDIUM'
      };
    }
    
    return this.generateGenericFix(issue);
  }
  
  generateTypeMismatchFix(issue) {
    return {
      title: '类型不匹配',
      description: issue.message,
      fixCode: '// 检查变量类型声明和赋值是否匹配\n// 可能需要显式类型转换或修改函数签名',
      explanation: 'Swift 是强类型语言，确保类型一致性',
      severity: 'MEDIUM'
    };
  }
  
  generateUIConstraintFix(issue) {
    return {
      title: 'UI约束问题',
      description: issue.message,
      fixCode: '// 检查 Auto Layout 约束\n// 确保约束不冲突且完整\nview.translatesAutoresizingMaskIntoConstraints = false',
      explanation: 'Auto Layout 约束需要唯一且完整',
      severity: 'MEDIUM'
    };
  }
  
  generateGenericFix(issue) {
    return {
      title: '问题修复建议',
      description: issue.message,
      fixCode: '// 请根据具体错误信息进行修复',
      explanation: '查看错误详情，参考官方文档或社区解决方案',
      severity: 'LOW'
    };
  }
  
  suggestMissingImportOrDeclaration(issue) {
    const message = issue.message.toLowerCase();
    
    if (message.includes('uikit')) {
      return 'import UIKit';
    }
    
    if (message.includes('swiftui')) {
      return 'import SwiftUI';
    }
    
    if (message.includes('swiftdata')) {
      return 'import SwiftData';
    }
    
    return '// 检查是否需要导入模块或声明缺失的符号';
  }
  
  suggestTypeConversion(issue) {
    return '// 示例类型转换:\n// let value = someValue as? TargetType\n// 或使用 guard let 安全解包';
  }
}

class NotificationSystem {
  constructor(config) {
    this.config = config;
    this.notificationHistory = [];
  }
  
  async sendNotification(issue, fixSuggestion) {
    const notification = {
      id: Date.now(),
      timestamp: new Date().toISOString(),
      severity: fixSuggestion.severity || 'MEDIUM',
      issue: issue,
      fixSuggestion: fixSuggestion,
      project: this.config.project.name,
      file: issue.file || '未知文件'
    };
    
    this.notificationHistory.push(notification);
    
    // 立即显示重要通知
    if (this.config.notifications.immediateFor.includes(issue.type) || 
        notification.severity === 'HIGH') {
      await this.showImmediateNotification(notification);
    } else {
      // 批量处理普通通知
      this.queueNotification(notification);
    }
    
    // 保存到日志文件
    this.logNotification(notification);
  }
  
  async showImmediateNotification(notification) {
    // 控制台输出
    console.log('\n' + '='.repeat(60));
    console.log(`🚨 主动BUG拦截 - ${notification.timestamp}`);
    console.log('='.repeat(60));
    
    console.log(`📊 问题类型: ${ERROR_TYPES[notification.issue.type] || notification.issue.type}`);
    console.log(`📁 文件位置: ${notification.file}`);
    
    if (notification.issue.line > 0) {
      console.log(`📍 行号: ${notification.issue.line}:${notification.issue.column}`);
    }
    
    console.log(`❌ 错误信息: ${notification.issue.message}`);
    console.log(`💡 修复建议: ${notification.fixSuggestion.title}`);
    console.log(`📝 问题描述: ${notification.fixSuggestion.description}`);
    console.log(`🔧 修复代码:\n${notification.fixSuggestion.fixCode}`);
    console.log(`📚 解释说明: ${notification.fixSuggestion.explanation}`);
    console.log('='.repeat(60) + '\n');
    
    // 桌面通知
    if (this.config.notifications.channels.includes('desktop')) {
      notifier.notify({
        title: `🚨 ${notification.project} - ${ERROR_TYPES[notification.issue.type] || notification.issue.type}`,
        message: `${notification.file}: ${notification.issue.message}`,
        subtitle: notification.fixSuggestion.title,
        sound: true,
        wait: true
      });
    }
  }
  
  queueNotification(notification) {
    // 简单实现：立即显示所有通知
    this.showImmediateNotification(notification);
  }
  
  logNotification(notification) {
    const logEntry = {
      timestamp: notification.timestamp,
      type: notification.issue.type,
      file: notification.file,
      message: notification.issue.message,
      fix: notification.fixSuggestion.title
    };
    
    const logFile = path.join(process.cwd(), 'monitor-logs.json');
    let logs = [];
    
    try {
      const existing = fs.readFileSync(logFile, 'utf8');
      logs = JSON.parse(existing);
    } catch (error) {
      // 文件不存在或格式错误，创建新文件
    }
    
    logs.push(logEntry);
    
    // 只保留最近100条日志
    if (logs.length > 100) {
      logs = logs.slice(-100);
    }
    
    fs.writeFileSync(logFile, JSON.stringify(logs, null, 2));
  }
  
  getStats() {
    const stats = {
      total: this.notificationHistory.length,
      byType: {},
      bySeverity: {
        HIGH: 0,
        MEDIUM: 0,
        LOW: 0
      }
    };
    
    for (const notification of this.notificationHistory) {
      stats.byType[notification.issue.type] = (stats.byType[notification.issue.type] || 0) + 1;
      stats.bySeverity[notification.severity] = (stats.bySeverity[notification.severity] || 0) + 1;
    }
    
    return stats;
  }
}

class MonitorSystem {
  constructor(config) {
    this.config = config;
    this.fileWatcher = new FileWatcher(config.project.path, config.monitoring);
    this.buildExecutor = new BuildExecutor(config.project.path, config.monitoring);
    this.staticAnalyzer = new StaticAnalyzer(config.project.path);
    this.fixEngine = new FixSuggestionEngine();
    this.notificationSystem = new NotificationSystem(config);
    
    this.isRunning = false;
    this.scheduledTimer = null;
    this.lastAnalysisTime = null;
  }
  
  async start() {
    console.log('🚀 启动 iOS 记账应用实时监控系统');
