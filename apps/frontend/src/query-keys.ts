/**
 * Query Key Factories
 * @see https://tkdodo.eu/blog/effective-react-query-keys#use-query-key-factories
 */

const QueryKeys = {
	taskList: () => ["authed", "taskList"] as const,
};

export default QueryKeys;
