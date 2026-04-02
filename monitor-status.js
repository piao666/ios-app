#!/usr/bin/env node

/**
 * 监控状态查看脚本
 * 使用方法: node monitor-status.js
 */

const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);
const fs = require('fs');
const path = require('path');

console.log('📊 iOS记账应用监控系统状态报告');
console.log('='.repeat(60));
console.log(`⏰ 检查时间: ${new Date().toLocaleString('zh-CN')}`);
console.log('');

// 1. 检查Node.js进程
async function checkProcesses() {
  console.log('🔍 检查Node.js进程...');
  try {
    const { stdout } = await execPromise('tasklist /FI "IMAGENAME eq node.exe" /FO CSV');
    const lines = stdout.trim().split('\n').slice(1); // 跳过标题行
    
    if (lines.length === 0 || lines[0].includes('没有运行')) {
      console.log('   ❌ 没有Node.js进程在运行');
      return;
    }
    
    console.log(`   ✅ 发现 ${lines.length} 个Node.js进程`);
    
    lines.forEach((line, index) => {
      const parts = line.replace(/"/g, '').split(',');
      if (parts.length >= 5) {
        const pid = parts[1];
        const memory = parts[4];
        console.log(`   ${index + 1}. PID: ${pid}, 内存: ${memory}`);
      }
    });
  } catch (error) {
    console.log('   ⚠️ 无法获取进程信息:', error.message);
  }
  console.log('');
}

// 2. 检查监控脚本文件
function checkMonitorFiles() {
  console.log('📂 检查监控脚本文件...');
  const files = [
    'monitor-start.js',
    'monitor-system.js',
    'build-trigger.js',
    'check-monitor.js'
  ];
  
  files.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
      const stats = fs.statSync(filePath);
      const sizeKB = (stats.size / 1024).toFixed(1);
      console.log(`   ✅ ${file}: ${sizeKB} KB`);
    } else {
      console.log(`   ❌ ${file}: 不存在`);
    }
  });
  console.log('');
}

// 3. 检查日志文件
function checkLogs() {
  console.log('📝 检查日志文件...');
  const logsDir = path.join(__dirname, 'logs');
  
  if (!fs.existsSync(logsDir)) {
    console.log('   ℹ️ 日志目录不存在（监控可能刚开始运行）');
    return;
  }
  
  const logFiles = fs.readdirSync(logsDir).filter(f => f.endsWith('.log'));
  
  if (logFiles.length === 0) {
    console.log('   ℹ️ 暂无日志文件');
  } else {
    console.log(`   ✅ 发现 ${logFiles.length} 个日志文件:`);
    logFiles.slice(-5).forEach(file => { // 只显示最近5个
      const filePath = path.join(logsDir, file);
      const stats = fs.statSync(filePath);
      const sizeKB = (stats.size / 1024).toFixed(1);
      console.log(`      - ${file}: ${sizeKB} KB`);
    });
  }
  console.log('');
}

// 4. 检查依赖
function checkDependencies() {
  console.log('📦 检查依赖状态...');
  const packagePath = path.join(__dirname, 'package.json');
  
  if (!fs.existsSync(packagePath)) {
    console.log('   ❌ package.json 不存在');
    return;
  }
  
  try {
    const packageData = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
    const deps = Object.keys(packageData.dependencies || {});
    
    console.log(`   ✅ 项目: ${packageData.name || '未命名'}`);
    console.log(`   ✅ 版本: ${packageData.version || '未设置'}`);
    console.log(`   ✅ 依赖: ${deps.length} 个`);
    
    deps.forEach(dep => {
      try {
        require(dep);
        console.log(`      ✅ ${dep}: 已加载`);
      } catch (e) {
        console.log(`      ❌ ${dep}: 加载失败`);
      }
    });
  } catch (error) {
    console.log('   ❌ 读取package.json失败:', error.message);
  }
  console.log('');
}

// 5. 提供操作建议
function provideRecommendations() {
  console.log('💡 操作建议');
  console.log('-'.repeat(60));
  console.log('查看监控状态:');
  console.log('   node check-monitor.js');
  console.log('');
  console.log('启动监控:');
  console.log('   node monitor-start.js');
  console.log('');
  console.log('停止监控:');
  console.log('   taskkill /PID <PID> /F  (使用上面查到的PID)');
  console.log('');
  console.log('查看日志:');
  console.log('   如果有logs目录: Get-Content logs\\monitor-*.log -Tail 20');
  console.log('');
  console.log('='.repeat(60));
}

// 主函数
async function main() {
  await checkProcesses();
  checkMonitorFiles();
  checkLogs();
  checkDependencies();
  provideRecommendations();
}

main().catch(console.error);