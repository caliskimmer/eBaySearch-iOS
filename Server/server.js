const express = require('express');
const path = require('path');
const app = express();
const port = 8080;
const findingRouter = require('./finding');
const shoppingRouter = require('./shopping');
const searchRouter = require('./search');
const merchRouter = require('./merchandising');

app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    next();
});
app.use(express.urlencoded({ extended: true }));
app.use('/finding', findingRouter);
app.use('/shopping', shoppingRouter);
app.use('/search', searchRouter);
app.use('/merchandising', merchRouter);
app.use(express.static(path.join(__dirname, 'public/dist/front-end/')));

app.listen(port, () => console.log(`Example app listening on ${port}`));

