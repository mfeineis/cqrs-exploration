/* eslint-env node */
const app = require("express")();

const PORT = 8082;

const pretty = x => JSON.stringify(x, null, "  ");
const trace = (...rest) => console.log("> ", ...rest);

const actions = {
    emit: () => ({ type: "EMIT" }),
};

const readonlyBus = {
    subscribe: (topic, handler) => {
        (function loop() {
            trace(`bus.subscribe`, pretty(actions.emit()));
            handler(actions.emit());

            setTimeout(loop, 1000);
        }());
    },
};

const db = {
    emitted: {
        count: 0,
    },
};

// Projection from bus events
readonlyBus.subscribe("EMIT", msg => {
    db.emitted.count += 1;
});

app.get("/read", (req, res) => (
    res.send(db.emitted)
));

app.listen(PORT, () => console.log(`Reader running on port ${PORT}`))
