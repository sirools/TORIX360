const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
    entry: './src/js/main.js', // Point d'entrée
    output: {
        filename: 'main.js', // Nom du fichier de sortie
        path: path.resolve(__dirname, 'dist'), // Répertoire de sortie
        clean: true, // Nettoie le dossier dist avant de construire
    },
    mode: 'production', // Mode production
    plugins: [
        new HtmlWebpackPlugin({
            template: './src/index.html', // Template HTML de départ
            filename: 'index.html', // Nom du fichier HTML généré
            inject: 'body', // Ajoute les scripts dans <body>
        }),
        new CopyWebpackPlugin({
            patterns: [
                { from: './src/assets', to: 'assets' }, // Copie les assets dans dist
            ],
        }),
    ],
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['@babel/preset-env'], // Transpilation avec Babel
                    },
                },
            },
            {
                test: /\.(png|jpg|jpeg|gif|svg|gltf)$/,
                type: 'asset/resource', // Gérer les fichiers images et modèles
            },
        ],
    },
};


