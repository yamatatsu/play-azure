import { useStore } from "@tanstack/react-form";
import { Field, FieldError, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { useFieldContext } from "@/hooks/use-form-context.ts";

export default function TextField({
	label,
	placeholder = "",
	required = false,
}: {
	label: string;
	placeholder?: string;
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
			<Input
				id={field.name}
				value={field.state.value || ""}
				onChange={(e) => field.handleChange(e.target.value)}
				onBlur={field.handleBlur}
				placeholder={placeholder}
				aria-invalid={isInvalid}
			/>
			<FieldError errors={errorsIfTouched} />
		</Field>
	);
}
