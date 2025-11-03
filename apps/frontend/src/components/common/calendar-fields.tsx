import { useStore } from "@tanstack/react-form";
import { Field, FieldError, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { useFieldContext } from "@/hooks/use-form-context.ts";

export default function CalendarField({
	label,
	required = false,
}: {
	label: string;
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
				type="date"
				value={field.state.value || ""}
				onChange={(e) => field.handleChange(e.target.value)}
				onBlur={field.handleBlur}
				min={new Date().toISOString().split("T")[0]}
				aria-invalid={isInvalid}
			/>
			<FieldError errors={errorsIfTouched} />
		</Field>
	);
}
