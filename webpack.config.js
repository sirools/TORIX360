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
            publicPath: isProd ? '/TORIX360/dist/' : '/', // Chemin public pour prod ou dev
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
                {
                    test: /\.(png|jpe?g|gif)$/i, // Ajout de la règle pour les images
                    type: 'asset/resource',  // Garder l'extension du fichier (pas de renaming)
                    generator: {
                        filename: 'assets/images/[name][ext]', // Conserve le nom et l'extension des fichiers
                    },
                },
            ],
        },
        plugins: [
            new HtmlWebpackPlugin({
                template: './src/index.html',
                favicon: './src/favicon.ico', // Inclut le favicon dans le HTML généré
            }),
            new CopyWebpackPlugin({
                patterns: [
                    { from: './src/assets', to: 'assets' }, // Copie les assets vers dist
                ],
            }),
        ],
        devServer: {
            static: {
                directory: path.resolve(__dirname, 'dist'),
            },
            compress: true,
            port: 8080, // Définit le port du serveur local
            open: true, // Ouvre automatiquement le navigateur
        },
        mode: argv.mode || 'development', // Définit le mode par défaut à développement
    };
};