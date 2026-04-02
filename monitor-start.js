#!/usr/bin/env node

/**
 * iOS 记账应用 - 实时监控系统启动脚本
 * 简化版本，专注于文件监听和基础通知
 */

const path = require('path');
const chokidar = require('chokidar');
const notifier = require('node-notifier');

// 配置
const CONFIG = {
  project: {
    name: 'iOS记账应用',
    path: process.cwd(), // 默认当前目录
  },
  
  monitoring: {
    fileWatch: {
      enabled: true,
      extensions: ['.swift', '.xib', '.storyboard', '.plist'],
      debounceMs: 1000,
      ignorePatterns: ['**/build/**', '**/.git/**', '**/node_modules/**']
    }
  },
  
  notifications: {
    channels: ['console', 'desktop']
  }
};

class SimpleFileWatcher {
  constructor(projectPath, config) {
    this.projectPath = projectPath;
    this.config = config;
    this.watcher = null;
    this.fileChangeCount = 0;
  }
  
  start() {
    console.log('🚀 启动 iOS 记账应用实时监控雷达');
    console.log(`📂 项目路径: ${this.projectPath}`);
    console.log(`🎯 监控目标: ${this.config.project.name}`);
    console.log('='.repeat(60));
    
    if (!this.config.monitoring.fileWatch.enabled) {
      console.log('📁 文件监控已禁用');
      return;
    }
    
    console.log(`📁 开始监控项目目录: ${this.projectPath}`);
    console.log(`🔍 监控文件类型: ${this.config.monitoring.fileWatch.extensions.join(', ')}`);
    
    this.watcher = chokidar.watch(this.projectPath, {
      ignored: this.config.monitoring.fileWatch.ignorePatterns,
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: {
        stabilityThreshold: this.config.monitoring.fileWatch.debounceMs,
        pollInterval: 100
      },
      depth: 5
    });
    
    this.watcher.on('change', (filePath) => {
      const ext = path.extname(filePath);
      if (this.config.monitoring.fileWatch.extensions.includes(ext)) {
        this.fileChangeCount++;
        const relativePath = path.relative(this.projectPath, filePath);
        
        console.log(`\n📝 [${new Date().toLocaleTimeString()}] 检测到代码变化 (#${this.fileChangeCount})`);
        console.log(`📁 文件: ${relativePath}`);
        
        // 发送通知
        this.sendNotification(relativePath);
        
        // 记录到日志
        this.logFileChange(relativePath);
      }
    });
    
    this.watcher.on('add', (filePath) => {
      const ext = path.extname(filePath);
      if (this.config.monitoring.fileWatch.extensions.includes(ext)) {
        const relativePath = path.relative(this.projectPath, filePath);
        console.log(`📄 新增文件: ${relativePath}`);
      }
    });
    
    this.watcher.on('unlink', (filePath) => {
      const ext = path.extname(filePath);
      if (this.config.monitoring.fileWatch.extensions.includes(ext)) {
        const relativePath = path.relative(this.projectPath, filePath);
        console.log(`🗑️ 删除文件: ${relativePath}`);
      }
    });
    
    this.watcher.on('error', (error) => {
      console.error(`❌ 文件监控错误: ${error.message}`);
    });
    
    console.log('✅ 文件监控雷达已启动');
    console.log('🛡️ 现在开始实时监控代码变动...');
    console.log('='.repeat(60));
    
    // 显示监控状态
    this.showStatus();
  }
  
  sendNotification(filePath) {
    // 控制台通知
    console.log('🔔 检测到代码变动，准备进行语法检查...');
    
    // 桌面通知
    if (this.config.notifications.channels.includes('desktop')) {
      notifier.notify({
        title: '🚨 iOS记账应用 - 代码变动检测',
        message: `文件已修改: ${filePath}`,
        subtitle: '准备进行语法检查...',
        sound: true,
        wait: false
      });
    }
  }
  
  logFileChange(filePath) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      file: filePath,
      action: 'modified'
    };
    
    const logFile = path.join(process.cwd(), 'monitor-file-changes.json');
    let logs = [];
    
    try {
      const existing = require('fs').readFileSync(logFile, 'utf8');
      logs = JSON.parse(existing);
    } catch (error) {
      // 文件不存在或格式错误，创建新文件
    }
    
    logs.push(logEntry);
    
    // 只保留最近50条日志
    if (logs.length > 50) {
      logs = logs.slice(-50);
    }
    
    require('fs').writeFileSync(logFile, JSON.stringify(logs, null, 2));
  }
  
  showStatus() {
    console.log('\n📊 监控雷达状态:');
    console.log(`  项目: ${this.config.project.name}`);
    console.log(`  路径: ${this.projectPath}`);
    console.log(`  监控文件数: ${this.getWatchedFilesCount()}`);
    console.log(`  文件变动次数: ${this.fileChangeCount}`);
    console.log(`  启动时间: ${new Date().toLocaleString()}`);
    console.log('='.repeat(60));
  }
  
  getWatchedFilesCount() {
    if (!this.watcher) return 0;
    
    // 获取监控的文件列表
    const watched = this.watcher.getWatched();
    let count = 0;
    
    for (const dir in watched) {
      count += watched[dir].length;
    }
    
    return count;
  }
  
  stop() {
    if (this.watcher) {
      this.watcher.close();
      console.log('\n🛑 文件监控雷达已停止');
      console.log(`📊 统计信息:`);
      console.log(`  总文件变动次数: ${this.fileChangeCount}`);
      console.log(`  运行时长: ${this.getUptime()} 分钟`);
    }
  }
  
  getUptime() {
    const startTime = this.startTime || new Date();
    const uptimeMs = new Date() - startTime;
    return Math.round(uptimeMs / 60000); // 转换为分钟
  }
}

// 启动监控系统
const monitor = new SimpleFileWatcher(CONFIG.project.path, CONFIG);

// 捕获退出信号
process.on('SIGINT', () => {
  console.log('\n\n🛑 收到退出信号，正在关闭监控雷达...');
  monitor.stop();
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n\n🛑 收到终止信号，正在关闭监控雷达...');
  monitor.stop();
  process.exit(0);
});

// 启动监控
monitor.start();

// 保持进程运行
console.log('\n📡 监控雷达正在运行，按 Ctrl+C 停止监控...\n');

// 定时显示状态
setInterval(() => {
  console.log(`⏰ [${new Date().toLocaleTimeString()}] 监控雷达运行中... (已监控 ${monitor.fileChangeCount} 次文件变动)`);
}, 300000); // 每5分钟显示一次状态