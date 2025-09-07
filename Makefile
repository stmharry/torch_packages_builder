-include .env

GH_WORKFLOW_RUN = gh workflow run
BUILD_WHEELS = $(GH_WORKFLOW_RUN) build_wheels.yml

REPO_SUBDIR ?= .
INCLUDE_HASH ?= false

ifeq ("$(PRESET)","pt210-cu121")
	TORCH_VERSION = 2.1.0
	LIMIT_PYTHON = 3.10,3.11
	LIMIT_COMPUTE_PLATFORM = cpu,cu118,cu121

else ifeq ("$(PRESET)","pt240-cu124")
	TORCH_VERSION = 2.4.0
	LIMIT_PYTHON = 3.10,3.11,3.12
	LIMIT_COMPUTE_PLATFORM = cu124

else ifeq ("$(PRESET)","pt260-cu126")
	TORCH_VERSION = 2.6.0
	LIMIT_PYTHON = 3.10,3.11,3.12,3.13
	LIMIT_COMPUTE_PLATFORM = cu126

else
	TORCH_VERSION ?= 2.1.0,2.4.0,2.6.0
	LIMIT_PYTHON ?= 3.10,3.11,3.12,3.13
	LIMIT_COMPUTE_PLATFORM ?= cpu,cu118,cu121,cu124,cu126

endif

.PHONY: .check-%
.check-%:
	@if [ -z "${${*}}" ]; then echo "Environment variable $* not set" && exit 1; fi

.PHONY: default
default: .check-TARGET $(TARGET)

.PHONY: build-wheels
build-wheels: .check-REPO
build-wheels: .check-TORCH_VERSION
	@\
	  echo "Building wheels for $(REPO) @ $(REPO_TAG) ($(REPO_SUBDIR))" && \
	  echo "  - torch-version=$(TORCH_VERSION)" && \
	  echo "  - limit-python=$(LIMIT_PYTHON)" && \
	  echo "  - limit-compute-platform=$(LIMIT_COMPUTE_PLATFORM)" && \
	  echo "  - python-packages=$(PYTHON_PACKAGES)" && \
	  echo "  - include-hash=$(INCLUDE_HASH)" && \
	  $(BUILD_WHEELS) \
	  	-f "repo=$(REPO)" \
	  	$(if $(REPO_TAG),-f "repo-tag=$(REPO_TAG)") \
	  	$(if $(REPO_SUBDIR),-f "repo-subdir=$(REPO_SUBDIR)") \
	  	-f "torch-version=$(TORCH_VERSION)" \
	  	$(if $(LIMIT_PYTHON),-f "limit-python=$(LIMIT_PYTHON)") \
	  	$(if $(LIMIT_COMPUTE_PLATFORM),-f "limit-compute-platform=$(LIMIT_COMPUTE_PLATFORM)") \
	  	$(if $(PYTHON_PACKAGES),-f "python-packages=$(PYTHON_PACKAGES)") \
	  	$(if $(INCLUDE_HASH),-f "include-hash=$(INCLUDE_HASH)")

.PHONY: pointops
pointops: REPO = AIDirect/pointops
pointops: REPO_TAG = main
pointops: build-wheels

.PHONY: flash-attn
flash-attn: REPO = Dao-AILab/flash-attention
flash-attn: PYTHON_PACKAGES = packaging psutil
flash-attn: build-wheels

.PHONY: torch-cluster
torch-cluster: REPO = rusty1s/pytorch_cluster
torch-cluster: PYTHON_PACKAGES = scipy
torch-cluster: build-wheels

.PHONY: torch-scatter
torch-scatter: REPO = rusty1s/pytorch_scatter
torch-scatter: build-wheels

.PHONY: torch-sparse
torch-sparse: REPO = rusty1s/pytorch_sparse
torch-sparse: PYTHON_PACKAGES = scipy
torch-sparse: build-wheels

.PHONY: torch-spline-conv
torch-spline-conv: REPO = rusty1s/pytorch_spline_conv
torch-spline-conv: build-wheels

.PHONY: pyg-lib
pyg-lib: REPO = pyg-team/pyg-lib 
pyg-lib: PYTHON_PACKAGES = mkl-include==2022.2 mkl-static==2022.2
pyg-lib: build-wheels

.PHONY: spconv-cpu
spconv-cpu: REPO = AIDirect/spconv
spconv-cpu: REPO_TAG = main
spconv-cpu: LIMIT_COMPUTE_PLATFORM = cpu
spconv-cpu: PYTHON_PACKAGES = pccm==0.4.16 ccimport>=0.4.4 pybind11==2.13.6 fire numpy cumm==0.7.11
spconv-cpu: build-wheels
