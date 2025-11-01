import type { Task } from "../prisma/client.js";
import type { TaskStatus } from "../prisma/client.js";
import type { Prisma } from "../prisma/client.js";
import type { Resolver } from "@quramy/prisma-fabbrica/lib/internal";
export { resetSequence, registerScalarFieldValueGenerator, resetScalarFieldValueGenerator } from "@quramy/prisma-fabbrica/lib/internal";
type BuildDataOptions<TTransients extends Record<string, unknown>> = {
    readonly seq: number;
} & TTransients;
type TraitName = string | symbol;
type CallbackDefineOptions<TCreated, TCreateInput, TTransients extends Record<string, unknown>> = {
    onAfterBuild?: (createInput: TCreateInput, transientFields: TTransients) => void | PromiseLike<void>;
    onBeforeCreate?: (createInput: TCreateInput, transientFields: TTransients) => void | PromiseLike<void>;
    onAfterCreate?: (created: TCreated, transientFields: TTransients) => void | PromiseLike<void>;
};
export declare const initialize: (options: import("@quramy/prisma-fabbrica/lib/initialize.js").InitializeOptions) => void;
type TaskFactoryDefineInput = {
    id?: string;
    title?: string;
    description?: string;
    status?: TaskStatus;
    createdAt?: Date;
    updatedAt?: Date;
};
type TaskTransientFields = Record<string, unknown> & Partial<Record<keyof TaskFactoryDefineInput, never>>;
type TaskFactoryTrait<TTransients extends Record<string, unknown>> = {
    data?: Resolver<Partial<TaskFactoryDefineInput>, BuildDataOptions<TTransients>>;
} & CallbackDefineOptions<Task, Prisma.TaskCreateInput, TTransients>;
type TaskFactoryDefineOptions<TTransients extends Record<string, unknown> = Record<string, unknown>> = {
    defaultData?: Resolver<TaskFactoryDefineInput, BuildDataOptions<TTransients>>;
    traits?: {
        [traitName: TraitName]: TaskFactoryTrait<TTransients>;
    };
} & CallbackDefineOptions<Task, Prisma.TaskCreateInput, TTransients>;
type TaskTraitKeys<TOptions extends TaskFactoryDefineOptions<any>> = Exclude<keyof TOptions["traits"], number>;
export interface TaskFactoryInterfaceWithoutTraits<TTransients extends Record<string, unknown>> {
    readonly _factoryFor: "Task";
    build(inputData?: Partial<Prisma.TaskCreateInput & TTransients>): PromiseLike<Prisma.TaskCreateInput>;
    buildCreateInput(inputData?: Partial<Prisma.TaskCreateInput & TTransients>): PromiseLike<Prisma.TaskCreateInput>;
    buildList(list: readonly Partial<Prisma.TaskCreateInput & TTransients>[]): PromiseLike<Prisma.TaskCreateInput[]>;
    buildList(count: number, item?: Partial<Prisma.TaskCreateInput & TTransients>): PromiseLike<Prisma.TaskCreateInput[]>;
    pickForConnect(inputData: Task): Pick<Task, "id">;
    create(inputData?: Partial<Prisma.TaskCreateInput & TTransients>): PromiseLike<Task>;
    createList(list: readonly Partial<Prisma.TaskCreateInput & TTransients>[]): PromiseLike<Task[]>;
    createList(count: number, item?: Partial<Prisma.TaskCreateInput & TTransients>): PromiseLike<Task[]>;
    createForConnect(inputData?: Partial<Prisma.TaskCreateInput & TTransients>): PromiseLike<Pick<Task, "id">>;
}
export interface TaskFactoryInterface<TTransients extends Record<string, unknown> = Record<string, unknown>, TTraitName extends TraitName = TraitName> extends TaskFactoryInterfaceWithoutTraits<TTransients> {
    use(name: TTraitName, ...names: readonly TTraitName[]): TaskFactoryInterfaceWithoutTraits<TTransients>;
}
interface TaskFactoryBuilder {
    <TOptions extends TaskFactoryDefineOptions>(options?: TOptions): TaskFactoryInterface<{}, TaskTraitKeys<TOptions>>;
    withTransientFields: <TTransients extends TaskTransientFields>(defaultTransientFieldValues: TTransients) => <TOptions extends TaskFactoryDefineOptions<TTransients>>(options?: TOptions) => TaskFactoryInterface<TTransients, TaskTraitKeys<TOptions>>;
}
/**
 * Define factory for {@link Task} model.
 *
 * @param options
 * @returns factory {@link TaskFactoryInterface}
 */
export declare const defineTaskFactory: TaskFactoryBuilder;
