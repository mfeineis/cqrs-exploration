/* eslint-env node */
const app = require("express")();

const PORT = 8081;

const polyfill = window => {
    window.setTimeout = fn => setImmediate(fn);
};

polyfill(global);

const Elm = require("./dist/domain");

const pretty = x => JSON.stringify(x, null, "  ");
const trace = (...rest) => console.log("> ", ...rest);

const bus = {
    send: (evt) => (
        trace(`bus.send`, pretty(evt))
    ),
};

const actions = {
    produce: () => ({ type: "PRODUCE" }),
};

app.get("/produce", (req, res) => {
    const domain = Elm.Domain.worker();

    domain.ports.fromElm.subscribe(msg => {
        trace(`fromElm`, pretty(msg));

        const { type, payload } = msg;

        switch (type) {
        case "ACK":
            res.send({ messages: [{ text: "Produced something" }] });
            break;

        case "EMIT":
            bus.send(msg);
            break;

        default:
            res.status(400);
            res.send({
                messages: [{ error: true, text: "Something went wrong" }],
            });
            break;
        }
    });
    domain.ports.toElm.send(actions.produce());
});

app.listen(PORT, () => console.log(`Writer running on port ${PORT}`))
