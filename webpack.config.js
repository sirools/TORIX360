const path = require('path');  // Import du module path
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = (env, argv) => {
  const isProd = argv.mode === 'production';

  return {
    entry: './src/js/main.js',
    output: {
      filename: 'main.js',
      path: path.resolve(__dirname, 'dist'),
      publicPath: isProd ? '/TORIX360/dist/' : '/',
      clean: true,
    },
    resolve: {
      extensions: ['.js'],
      alias: {
        '@js': path.resolve(__dirname, 'src/js'),
      },
    },
    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: 'babel-loader',
        },
        {
          test: /\.(png|jpe?g|gif)$/i,
          type: 'asset/resource',
          generator: {
            filename: 'assets/images/[name][ext]',
          },
        },
        {
          test: /\.css$/,
          use: [
            MiniCssExtractPlugin.loader, 
            'css-loader',
          ],
        },
      ],
    },
    plugins: [
      new HtmlWebpackPlugin({
        template: './src/index.html',
        favicon: './src/favicon.ico',
      }),
      new CopyWebpackPlugin({
        patterns: [
          { from: './src/assets', to: 'assets' },
        ],
      }),
      new MiniCssExtractPlugin({
        filename: 'styles/main.css', 
      }),
    ],
    devServer: {
      static: {
        directory: path.resolve(__dirname, 'dist'),
        publicPath: '/',
      },
      hot: true,
      compress: true,
      port: 8080,
      open: true,
      historyApiFallback: true,
    },
    mode: argv.mode || 'development',
  };
};