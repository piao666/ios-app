#!/usr/bin/env node

/**
 * 监控日志查看工具
 * 使用方法: node monitor-logs.js [选项]
 * 选项: --tail N (查看最后N行), --follow (实时跟踪)
 */

const fs = require('fs');
const path = require('path');

console.log('📝 监控日志查看工具');
console.log('='.repeat(60));

const logsDir = path.join(__dirname, 'logs');

// 检查日志目录
if (!fs.existsSync(logsDir)) {
  console.log('ℹ️ 日志目录不存在');
  console.log('监控可能刚开始运行，还没有生成日志文件');
  console.log('监控日志会保存在: logs/ 目录');
  process.exit(0);
}

// 获取所有日志文件
const logFiles = fs.readdirSync(logsDir)
  .filter(f => f.endsWith('.log'))
  .sort()
  .reverse(); // 最新的在前

if (logFiles.length === 0) {
  console.log('ℹ️ 暂无日志文件');
  process.exit(0);
}

console.log(`📂 发现 ${logFiles.length} 个日志文件\n`);

// 显示最近的日志文件
const recentFile = logFiles[0];
const filePath = path.join(logsDir, recentFile);

console.log(`📄 最新日志文件: ${recentFile}`);
console.log('-'.repeat(60));

// 读取并显示日志内容
try {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n').filter(line => line.trim());
  
  // 显示最后30行
  const tailLines = lines.slice(-30);
  
  tailLines.forEach(line => {
    console.log(line);
  });
  
  console.log('\n' + '='.repeat(60));
  console.log(`📊 总计: ${lines.length} 行日志`);
  console.log(`💡 提示: 使用文本编辑器打开 ${filePath} 查看完整日志`);
  
} catch (error) {
  console.error('❌ 读取日志失败:', error.message);
}

// 显示所有日志文件列表
console.log('\n📋 所有日志文件:');
logFiles.slice(0, 10).forEach((file, index) => {
  const filePath = path.join(logsDir, file);
  const stats = fs.statSync(filePath);
  const sizeKB = (stats.size / 1024).toFixed(1);
  const date = stats.mtime.toLocaleString('zh-CN');
  console.log(`   ${index + 1}. ${file} (${sizeKB} KB, ${date})`);
});

console.log('\n✅ 日志查看完成');