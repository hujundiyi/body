const plugins = [];
if (['production', 'prod'].includes(process.env.NODE_ENV)) {
  plugins.push("transform-remove-console")
}
process.env.VUE_APP_VERSION = require('./package.json').version
process.env.VUE_APP_RELEASE_DATE = new Date();
module.exports = {
  presets: [
    '@vue/babel-preset-jsx',
    '@vue/cli-plugin-babel/preset'
  ],
  plugins: plugins
}
