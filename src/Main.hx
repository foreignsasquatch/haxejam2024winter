import engine.App;

function main() {
  var app = new App({
    title: "fishy business",
    display: {w: 480, h: 360},
    desktop: {w: 480 * 2, h: 360 * 2},
    web: {w: 480, h: 360}
  });
  app.run(Game);
}