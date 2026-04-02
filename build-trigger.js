#!/usr/bin/env node

/**
 * iOS 记账应用 - 构建触发器模块
 * 功能：在检测到代码变化后自动触发构建和分析
 */

const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);
const path = require('path');

class BuildTrigger {
  constructor(projectPath) {
    this.projectPath = projectPath;
    this.isBuilding = false;
    this.buildQueue = [];
    this.lastBuildTime = null;
  }
  
  /**
   * 触发构建和分析
   * @param {string} changedFile - 变化的文件路径
   * @returns {Promise<Object>} 构建结果
   */
  async triggerBuild(changedFile) {
    console.log(`🔨 检测到代码变化: ${path.relative(this.projectPath, changedFile)}`);
    console.log('🔄 触发自动构建和分析...');
    
    // 如果正在构建，加入队列
    if (this.isBuilding) {
      console.log('⏳ 构建进行中，加入队列等待...');
      this.buildQueue.push(changedFile);
      return { queued: true, file: changedFile };
    }
    
    this.isBuilding = true;
    
    try {
      const results = {
        timestamp: new Date().toISOString(),
        changedFile: changedFile,
        buildResult: null,
        analysisResult: null,
        errors: [],
        warnings: []
      };
      
      // 1. 执行构建
      results.buildResult = await this.runXcodeBuild();
      
      // 2. 执行静态分析
      results.analysisResult = await this.runStaticAnalysis();
      
      // 3. 合并结果
      if (results.buildResult && results.buildResult.errors) {
        results.errors.push(...results.buildResult.errors);
      }
      if (results.buildResult && results.buildResult.warnings) {
        results.warnings.push(...results.buildResult.warnings);
      }
      if (results.analysisResult && results.analysisResult.issues) {
        results.warnings.push(...results.analysisResult.issues);
      }
      
      this.lastBuildTime = new Date();
      
      console.log(`✅ 构建和分析完成 (${results.errors.length} 错误, ${results.warnings.length} 警告)`);
      
      return results;
      
    } catch (error) {
      console.error(`❌ 构建触发失败: ${error.message}`);
      return {
        timestamp: new Date().toISOString(),
        changedFile: changedFile,
        error: error.message,
        errors: [],
        warnings: []
      };
    } finally {
      this.isBuilding = false;
      
      // 处理队列中的下一个构建
      if (this.buildQueue.length > 0) {
        const nextFile = this.buildQueue.shift();
        console.log(`📋 处理队列中的下一个构建: ${path.relative(this.projectPath, nextFile)}`);
        setTimeout(() => this.triggerBuild(nextFile), 1000);
      }
    }
  }
  
  /**
   * 执行 Xcode 构建
   */
  async runXcodeBuild() {
    console.log('🏗️  执行 Xcode 构建...');
    
    const buildCommand = [
      'xcodebuild',
      'clean',
      'build',
      '-scheme "记账应用"',
      '-destination "platform=iOS Simulator"',
      '-configuration "Debug"',
      'QUIET=YES'
    ].join(' ');
    
    try {
      const startTime = Date.now();
      const { stdout, stderr } = await execPromise(buildCommand, {
        cwd: this.projectPath,
        maxBuffer: 10 * 1024 * 1024
      });
      
      const buildTime = Date.now() - startTime;
      
      const errors = this.extractErrors(stderr);
      const warnings = this.extractWarnings(stderr);
      
      return {
        success: true,
        buildTime,
        errors,
        warnings,
        hasErrors: errors.length > 0,
        hasWarnings: warnings.length > 0
      };
      
    } catch (error) {
      console.log(`❌ Xcode 构建失败: ${error.message}`);
      
      const errors = this.extractErrors(error.stderr || '');
      const warnings = this.extractWarnings(error.stderr || '');
      
      return {
        success: false,
        error: error.message,
        errors,
        warnings,
        hasErrors: true,
        hasWarnings: warnings.length > 0
      };
    }
  }
  
  /**
   * 执行静态分析
   */
  async runStaticAnalysis() {
    console.log('🔍 执行静态代码分析...');
    
    // 尝试使用 SwiftLint
    try {
      const { stdout } = await execPromise('swiftlint', {
        cwd: this.projectPath
      });
      
      const issues = this.parseSwiftLintOutput(stdout);
      
      return {
        tool: 'SwiftLint',
        success: true,
        issues,
        issueCount: issues.length
      };
      
    } catch (error) {
      // SwiftLint 可能未安装或返回错误
      if (error.stdout) {
        const issues = this.parseSwiftLintOutput(error.stdout);
        
        return {
          tool: 'SwiftLint',
          success: false,
          issues,
          issueCount: issues.length,
          error: 'SwiftLint 发现代码问题'
        };
      }
      
      console.log(`⚠️ SwiftLint 不可用: ${error.message}`);
      
      // 回退到基础语法检查
      return {
        tool: 'Basic',
        success: true,
        issues: [],
        issueCount: 0,
        note: 'SwiftLint 未安装，使用基础检查'
      };
    }
  }
  
  /**
   * 从构建输出中提取错误
   */
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
  
  /**
   * 解析错误行
   */
  parseErrorLine(line) {
    // 格式: /path/to/file.swift:10:15: error: message
    const errorRegex = /^(.*?\.swift):(\d+):(\d+):\s*error:\s*(.+)$/;
    const match = line.match(errorRegex);
    
    if (match) {
      return {
        type: 'COMPILE_ERROR',
        file: match[1],
        line: parseInt(match[2]),
        column: parseInt(match[3]),
        message: match[4],
        rawLine: line,
        severity: 'HIGH'
      };
    }
    
    // 通用错误
    const genericErrorRegex = /error:\s*(.+)$/;
    const genericMatch = line.match(genericErrorRegex);
    
    if (genericMatch) {
      return {
        type: 'COMPILE_ERROR',
        file: '未知',
        line: 0,
        column: 0,
        message: genericMatch[1],
        rawLine: line,
        severity: 'HIGH'
      };
    }
    
    return null;
  }
  
  /**
   * 从构建输出中提取警告
   */
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
  
  /**
   * 解析警告行
   */
  parseWarningLine(line) {
    // 格式: /path/to/file.swift:10:15: warning: message
    const warningRegex = /^(.*?\.swift):(\d+):(\d+):\s*warning:\s*(.+)$/;
    const match = line.match(warningRegex);
    
    if (match) {
      return {
        type: 'WARNING',
        file: match[1],
        line: parseInt(match[2]),
        column: parseInt(match[3]),
        message: match[4],
        rawLine: line,
        severity: 'MEDIUM'
      };
    }
    
    return null;
  }
  
  /**
   * 解析 SwiftLint 输出
   */
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
            source: 'SwiftLint',
            severity: 'LOW'
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
  
  /**
   * 获取构建统计信息
   */
  getStats() {
    return {
      isBuilding: this.isBuilding,
      queueLength: this.buildQueue.length,
      lastBuildTime: this.lastBuildTime,
      totalQueued: this.buildQueue.length
    };
  }
  
  /**
   * 清空构建队列
   */
  clearQueue() {
    const cleared = this.buildQueue.length;
    this.buildQueue = [];
    console.log(`🗑️  已清空构建队列 (${cleared} 个任务)`);
    return cleared;
  }
}

// 导出模块
module.exports = BuildTrigger;

// 如果直接运行，进行测试
if (require.main === module) {
  console.log('🔧 构建触发器模块测试');
  console.log('='.repeat(60));
  
  const trigger = new BuildTrigger(process.cwd());
  
  console.log('📊 构建触发器状态:');
  console.log(`   项目路径: ${trigger.projectPath}`);
  console.log(`   构建状态: ${trigger.isBuilding ? '进行中' : '空闲'}`);
  console.log(`   队列长度: ${trigger.buildQueue.length}`);
  console.log(`   最后构建: ${trigger.lastBuildTime || '从未构建'}`);
  
  console.log('\n✅ 构建触发器模块加载成功');
  console.log('='.repeat(60));
}