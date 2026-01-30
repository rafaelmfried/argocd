CLUSTER_NAME := testcluster
K3D := k3d

.PHONY: start stop status

start:
	@echo "Starting the service..."
	$(K3D) cluster start $(CLUSTER_NAME)
	@echo "Service started."
stop:
	@echo "Stopping the service..."
	$(K3D) cluster stop $(CLUSTER_NAME)
	@echo "Service stopped."
status:
	@echo "Checking service status..."
	$(K3D) cluster list | grep $(CLUSTER_NAME) && echo "Service is running." || echo "Service is not running."