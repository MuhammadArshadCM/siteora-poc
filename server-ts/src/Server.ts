import "@tsed/platform-express";
import { Configuration } from "@tsed/di";
import { RulesController } from "./controllers/RulesController.js";

@Configuration({
  httpPort: Number(process.env.POC_PORT ?? 8766),
  httpsPort: false,
  disableComponentsScan: true,
  logger: { level: "info", disableRoutesSummary: false },
  mount: {
    "/": [RulesController],
  },
  middlewares: [],
})
export class Server {}
