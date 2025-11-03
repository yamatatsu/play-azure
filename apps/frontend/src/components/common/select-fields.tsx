import { useStore } from "@tanstack/react-form";
import { Field, FieldError, FieldLabel } from "@/components/ui/field";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";
import { useFieldContext } from "@/hooks/use-form-context.ts";

export default function SelectField({
	label,
	placeholder = "",
	options,
	isLoading = false,
	required = false,
}: {
	label: string;
	options: { code: string; name: string }[];
	placeholder?: string;
	isLoading?: boolean;
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

			<Select
				value={field.state.value || ""}
				onValueChange={field.handleChange}
				disabled={isLoading}
			>
				<SelectTrigger className="w-full" aria-invalid={isInvalid}>
					<SelectValue
						placeholder={isLoading ? "読み込み中..." : placeholder}
					/>
				</SelectTrigger>
				<SelectContent>
					{options.map((option) => (
						<SelectItem key={option.code} value={option.code}>
							{option.name}
						</SelectItem>
					))}
				</SelectContent>
			</Select>
			<FieldError errors={errorsIfTouched} />
		</Field>
	);
}
