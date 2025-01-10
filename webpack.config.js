const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, argv) => {
    const isProd = argv && argv.mode === 'production'; // Vérifie si le mode est production

    return {
        entry: './src/js/main.js',
        output: {
            filename: 'main.js',
            path: path.resolve(__dirname, 'dist'),
            publicPath: isProd ? '/TORIX360/' : '/', // Chemin adapté à l'environnement
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
                favicon: './src/favicon.ico', // Inclut le favicon dans le fichier HTML généré
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
        mode: argv && argv.mode || 'development', // Définit le mode par défaut à développement
    };
};