const {defineConfig} = require('@vue/cli-service')
const path = require('path')
const name = process.env.VUE_APP_TITLE || ''
const isProd = (process.env.NODE_ENV === 'production');
const packageJson = require('./package.json')

function resolve(dir) {
    return path.join(__dirname, dir)
}

const packageOutputFile = () => {
    if ((process.env.NODE_ENV === 'production' || process.env.NODE_ENV === 'test')) {
        return {filename: 'js/[name].[contenthash:8].js', chunkFilename: 'js/[name].[contenthash:8].js'}
    }
    return {filename: 'js/[name].js', chunkFilename: 'js/[name].js'}
}

module.exports = defineConfig({
    // 打包后静态资源路径
    // publicPath: '../../',
    transpileDependencies: true,
    configureWebpack: {
        devtool: isProd ? false : 'source-map',
        name: name,
        resolve: {
            alias: {
                '@': resolve('src')
            }
        },
        output: packageOutputFile(),
        plugins: [
            new (require('webpack').DefinePlugin)({
                'process.env.PACKAGE_VERSION': JSON.stringify(packageJson.version)
            })
        ]
    },
    devServer: {
        // development server port 8000
        port: 8081,
        https: true,
        // ✅ 关闭 JS 报错时的整屏蒙层
        client: {
            overlay: false,
        },
        // If you want to turn on the proxy, please remove the mockjs /src/main.jsL11
        proxy: {
            [process.env.VUE_APP_BASE_API]: {
                target: 'http://8.137.21.100:8080',
                //  target: `http://192.168.110.193:8080`,
                // target: `http://192.168.110.235:8080`,
                changeOrigin: true,
                pathRewrite: {
                    ['^' + process.env.VUE_APP_BASE_API]: ''
                }
            }
        },
    },
    pluginOptions: {
        "style-resources-loader": {
            preProcessor: "less",
            patterns: [
                // 全局变量路径
                path.resolve(__dirname, "./src/assets/css/global.less"),
            ],
        },
    }
});
