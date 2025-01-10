const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, argv) => {
    const isProd = argv.mode === 'production'; // Vérifie si le mode est production

    return {
        entry: './src/js/main.js',
        output: {
            filename: 'main.js',
            path: path.resolve(__dirname, 'dist'),
            publicPath: isProd ? '/TORIX360/dist/' : '/', // Chemin public pour prod
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
                favicon: './src/favicon.ico', // Inclut le favicon
            }),
            new CopyWebpackPlugin({
                patterns: [
                    { from: './src/assets', to: 'assets' }, // Copie les assets vers dist
                    { from: './src/favicon.ico', to: '' }, // Copie le favicon à la racine de dist
                ],
            }),
        ],
        devServer: {
            static: {
                directory: path.resolve(__dirname, 'dist'),
            },
            compress: true,
            port: 8080, // Port pour le serveur local
            open: true, // Ouvre automatiquement le navigateur
        },
        mode: argv.mode || 'development', // Définit le mode par défaut à développement
    };
};