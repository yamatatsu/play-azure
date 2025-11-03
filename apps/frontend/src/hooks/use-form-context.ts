/**
 * Tanstack Form の Form Composition という実装方式
 * @see https://tanstack.com/form/latest/docs/framework/react/examples/large-form?path=examples%2Freact%2Flarge-form%2Fsrc%2Fhooks%2Fform-context.tsx
 */

import { createFormHookContexts } from "@tanstack/react-form";

export const { fieldContext, useFieldContext, formContext, useFormContext } =
	createFormHookContexts();
