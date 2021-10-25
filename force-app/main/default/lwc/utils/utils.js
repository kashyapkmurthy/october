import { ShowToastEvent } from "lightning/platformShowToastEvent";
import momentJs from "@salesforce/resourceUrl/momentjs_2_29_1";

export const TOAST = {
  VARIANT: {
    SUCCESS: "success",
    ERROR: "error",
    WARNING: "warning"
  },
  MODE: {
    DISMISSABLE: "dismissable", // default
    PESTER: "pester",
    STICKY: "sticky"
  }
};

export const newToast = ({ title = "", message = "" }) =>
  new ShowToastEvent({
    title,
    message
  });

export const newErrorToast = ({
  title = "Error",
  message = "",
  mode = TOAST.MODE.DISMISSABLE
}) =>
  new ShowToastEvent({
    title,
    message,
    variant: TOAST.VARIANT.ERROR,
    mode
  });

export const newSuccessToast = ({
  title = "Success",
  message = "",
  mode = TOAST.MODE.DISMISSABLE
}) =>
  new ShowToastEvent({
    title,
    message,
    variant: TOAST.VARIANT.SUCCESS,
    mode
  });

export const handleError = (error) => {
  let errorMessage;
  if (Array.isArray(error.body)) {
    errorMessage = error.body.map((e) => e.message).join(", ");
  } else {
    errorMessage = error?.body?.message || error?.message || error;
  }
  return errorMessage;
};

export const replaceStringWithPlaceholder = (text, replacementHandler) => {
  let result = "";

  let i = 0;
  while (true) {
    // eslint-disable-line no-constant-condition
    // Find the next opening or closing brace
    const open = text.indexOf("{", i);
    const close = text.indexOf("}", i);
    if (open < 0 && close < 0) {
      // Not found: copy the end of the string and break
      result += text.slice(i);
      break;
    }
    if (close > 0 && (close < open || open < 0)) {
      if (text.charAt(close + 1) !== "}") {
        throw new Error("format stringFormatBraceMismatch");
      }

      result += text.slice(i, close + 1);
      i = close + 2;
      continue;
    }

    // Copy the string before the brace
    result += text.slice(i, open);
    i = open + 1;

    // Check for double braces (which display as one and are not arguments)
    if (text.charAt(i) === "{") {
      result += "{";
      i += 1;
      continue;
    }

    if (close < 0) {
      throw new Error("format stringFormatBraceMismatch");
    }

    // Find the closing brace

    // Get the string between the braces, and split it around the ':' (if any)
    const brace = text.substring(i, close);
    const colonIndex = brace.indexOf(":");
    const name = colonIndex < 0 ? brace : brace.substring(0, colonIndex);

    var keys = Object.keys(replacementHandler);
    if (keys.indexOf(name) > -1) {
      if (
        replacementHandler[name] !== undefined &&
        replacementHandler[name] !== null &&
        replacementHandler[name] !== ""
      ) {
        result += replacementHandler[name];
      } else {
        result += "";
      }
    } else {
      result += " ";
    }

    i = close + 1;
  }

  return result;
};