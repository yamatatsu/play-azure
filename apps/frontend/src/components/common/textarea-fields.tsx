import { useStore } from "@tanstack/react-form";
import { Field, FieldError, FieldLabel } from "@/components/ui/field";
import { useFieldContext } from "@/hooks/use-form-context.ts";
import { Textarea } from "../ui/textarea";

export default function TextareaField({
	label,
	placeholder = "",
	rows = 4,
	required = false,
}: {
	label: string;
	placeholder?: string;
	rows?: number;
	required?: boolean;
}) {
	const field = useFieldContext<string>();

	const isTouched = useStore(field.store, (state) => state.meta.isTouched);
	const isValid = useStore(field.store, (state) => state.meta.isValid);
	const errors = useStore(field.store, (state) => state.meta.errors);

	const isInvalid = isTouched && !isValid;
	const errorsIfTouched = isTouched ? errors : undefined;

	return (
		<Field data-invalid={isInvalid}>
			<FieldLabel htmlFor={field.name}>
				{label}
				{required && <span className="text-red-500">*</span>}
			</FieldLabel>
			<Textarea
				id={field.name}
				value={field.state.value || ""}
				onChange={(e) => field.handleChange(e.target.value)}
				onBlur={field.handleBlur}
				placeholder={placeholder}
				rows={rows}
				aria-invalid={isInvalid}
			/>
			<FieldError errors={errorsIfTouched} />
		</Field>
	);
}
