import { useStore } from "@tanstack/react-form";
import { Field, FieldError, FieldLabel } from "@/components/ui/field";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { useFieldContext } from "@/hooks/use-form-context.ts";

export default function RadioGroupField({
	label,
	items,
	required = false,
}: {
	label: string;
	items: { code: string; name: string }[];
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

			<RadioGroup
				value={field.state.value || ""}
				onValueChange={field.handleChange}
				className="grid grid-cols-1 sm:grid-cols-2 gap-2"
			>
				{items.map((item) => (
					<div key={item.code} className="flex items-center gap-3">
						<RadioGroupItem value={item.code} id={item.code} />
						<Label htmlFor={item.code}>{item.name}</Label>
					</div>
				))}
			</RadioGroup>
			<FieldError errors={errorsIfTouched} />
		</Field>
	);
}
