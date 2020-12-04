#include <stdio.h>
#include <hwloc.h>
#include <assert.h>

int main(int argc, char *argv[])
{
	size_t i, coreCount;
	hwloc_topology_t topology;
	hwloc_obj_t obj;

	if(hwloc_topology_init(&topology))
	{
		fprintf(stderr, "hwloc_topology_init failed\n");
		exit(EXIT_FAILURE);
	}

	if(hwloc_topology_load(topology))
	{
		fprintf(stderr, "hwloc_topology_load failed\n");
		exit(EXIT_FAILURE);
	}

	coreCount = hwloc_get_nbobjs_by_type(topology, HWLOC_OBJ_CORE);
	printf("coreCount = %zu\n", coreCount);

	for(i = 0; i < coreCount; i++)
	{
		obj = hwloc_get_obj_by_type(topology, HWLOC_OBJ_PU, i);
		assert(obj != NULL);
		assert(obj->parent != NULL);
		printf("obj->parent->type = %d, i = %zu\n", obj->parent->type, i);
		assert(obj->parent->type == HWLOC_OBJ_CORE);
	}

	printf("hwloc test OK\n");
}
