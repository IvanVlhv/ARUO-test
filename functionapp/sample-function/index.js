module.exports = async function (context, req) {
  context.res = {
    status: 200,
    body: {
      message: "Hello from private Function App",
      path: req.url,
      timestamp: new Date().toISOString()
    }
  };
};
