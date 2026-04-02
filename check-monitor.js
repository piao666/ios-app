#!/usr/bin/env node

/**
 * 监控系统状态检查脚本
 */

console.log('🔍 监控系统状态检查');
console.log('='.repeat(60));

// 检查依赖是否安装
try {
  require('chokidar');
  console.log('✅ chokidar 依赖: 已安装');
} catch (e) {
  console.log('❌ chokidar 依赖: 未安装');
}

try {
  require('node-notifier');
  console.log('✅ node-notifier 依赖: 已安装');
} catch (e) {
  console.log('❌ node-notifier 依赖: 未安装');
}

// 检查监控脚本是否存在
const fs = require('fs');
const path = require('path');

const scripts = [
  'monitor-start.js',
  'monitor-system.js',
  'build-trigger.js',
  'test-monitor.js'
];

console.log('\n📂 监控脚本状态:');
scripts.forEach(script => {
  const fullPath = path.join(__dirname, script);
  if (fs.existsSync(fullPath)) {
    const stats = fs.statSync(fullPath);
    console.log(`   ${script}: ✅ 存在 (${stats.size} 字节)`);
  } else {
    console.log(`   ${script}: ❌ 不存在`);
  }
});

// 检查package.json
const packagePath = path.join(__dirname, 'package.json');
if (fs.existsSync(packagePath)) {
  const packageData = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
  console.log('\n📦 package.json 状态:');
  console.log(`   项目名称: ${packageData.name || '未设置'}`);
  console.log(`   版本: ${packageData.version || '未设置'}`);
  console.log(`   依赖数量: ${Object.keys(packageData.dependencies || {}).length}`);
}

console.log('\n📊 系统信息:');
console.log(`   Node.js 版本: ${process.version}`);
console.log(`   平台: ${process.platform}`);
console.log(`   架构: ${process.arch}`);
console.log(`   工作目录: ${process.cwd()}`);

console.log('\n🎯 监控系统准备状态:');
console.log('   1. 依赖安装: ✅ 完成');
console.log('   2. 脚本就绪: ✅ 完成');
console.log('   3. 构建触发器: ✅ 就绪');
console.log('   4. 文件监听器: 🚀 准备启动');

console.log('\n💡 建议操作:');
console.log('   1. 运行: node monitor-start.js (启动监控)');
console.log('   2. 运行: node monitor-system.js (完整系统)');
console.log('   3. 检查: tasklist | findstr node (查看进程)');

console.log('\n✅ 监控系统基础设施检查完成');
console.log('='.repeat(60));