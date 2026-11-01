// 测试进程的环境变量，在任何模块加载之前执行。
// dotenv 不覆盖已存在的变量，所以这里显式置空 Key：即使本机 .env 里配了真实 Key，测试也不会调用模型、不会产生费用。
process.env.LLM_API_KEY = '';
process.env.RATE_LIMIT_PER_MINUTE = '3';
