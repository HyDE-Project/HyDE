import AIContainer, { QSCodyAI } from "./AIWidget.js";
import CodyAI from "./AIService.js";
import { AIService } from './AIService.js';
import { AIWidget } from './AIWidget.js';

export default AIContainer;
export {
  CodyAI,
  AIContainer,
  QSCodyAI
};
export default {
  service: AIService,
  widget: AIWidget,
};