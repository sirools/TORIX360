const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
    entry: './src/js/main.js',
    output: {
        filename: 'main.js',
        path: path.resolve(__dirname, 'dist'),
        clean: true,
    },
    resolve: {
        extensions: ['.js'],
        alias: {
            '@js': path.resolve(__dirname, 'src/js'), // Alias pour le répertoire JS
        },
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: 'babel-loader',
            },
        ],
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: './src/index.html',
            favicon: './src/favicon.ico', // Ligne ajoutée pour le favicon
        }),
        new CopyWebpackPlugin({
            patterns: [
                { from: './src/assets', to: 'assets' }, // Copie les assets vers dist
                { from: './src/favicon.ico', to: '' }, // Copie le favicon à la racine de dist
            ],
        }),
    ],
    mode: 'development',
};