#!/usr/bin/env node

console.log('🔧 简单测试脚本启动');

// 测试基本模块
try {
  const fs = require('fs');
  console.log('✅ fs 模块: 正常');
} catch (e) {
  console.log('❌ fs 模块错误:', e.message);
}

// 测试chokidar
try {
  const chokidar = require('chokidar');
  console.log('✅ chokidar 模块: 正常');
} catch (e) {
  console.log('❌ chokidar 模块错误:', e.message);
}

// 测试node-notifier
try {
  const notifier = require('node-notifier');
  console.log('✅ node-notifier 模块: 正常');
} catch (e) {
  console.log('❌ node-notifier 模块错误:', e.message);
}

// 测试路径
console.log('\n📁 当前目录:', process.cwd());
console.log('📄 脚本目录:', __dirname);

console.log('\n✅ 简单测试完成');