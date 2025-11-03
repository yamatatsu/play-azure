/**
 * Tanstack Form の Form Composition という実装方式
 * @see https://tanstack.com/form/latest/docs/framework/react/examples/large-form?path=examples%2Freact%2Flarge-form%2Fsrc%2Fhooks%2Fform.tsx
 */

import { createFormHook } from "@tanstack/react-form";
import { lazy } from "react";
import { Button } from "@/components/ui/button.tsx";
import {
	fieldContext,
	formContext,
	useFormContext,
} from "./use-form-context.ts";

const TextField = lazy(() => import("@/components/common/text-fields.tsx"));
const SelectField = lazy(() => import("@/components/common/select-fields.tsx"));
const RadioGroupField = lazy(
	() => import("@/components/common/radio-group-fields.tsx"),
);
const CalendarField = lazy(
	() => import("@/components/common/calendar-fields.tsx"),
);
const TextareaField = lazy(
	() => import("@/components/common/textarea-fields.tsx"),
);

export const { useAppForm, withForm, withFieldGroup } = createFormHook({
	fieldComponents: {
		TextField,
		SelectField,
		RadioGroupField,
		CalendarField,
		TextareaField,
	},
	formComponents: {
		SubscribeButton,
	},
	fieldContext,
	formContext,
});

function SubscribeButton({
	label,
	disabled,
}: {
	label: string;
	disabled: boolean;
}) {
	const form = useFormContext();
	return (
		<form.Subscribe selector={(state) => state.isSubmitting}>
			{(isSubmitting) => (
				<Button type="submit" disabled={isSubmitting || disabled} size="lg">
					{isSubmitting ? "送信中..." : label}
				</Button>
			)}
		</form.Subscribe>
	);
}
