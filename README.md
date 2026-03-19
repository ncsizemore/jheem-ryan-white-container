# JHEEM Ryan White Container

Docker container for the JHEEM Ryan White model (MSA + AJPH state analyses). Extends the shared [jheem-base](https://github.com/ncsizemore/jheem-base) image.

## Usage

The container is published to GitHub Container Registry:

```bash
docker pull ghcr.io/ncsizemore/jheem-ryan-white-model:2.2.1
```

### Batch Mode (Data Extraction)

```bash
docker run --rm \
  -v $(pwd)/simulations:/app/simulations:ro \
  -v $(pwd)/output:/output \
  ghcr.io/ncsizemore/jheem-ryan-white-model:2.2.1 batch \
  --city C.12580 \
  --scenarios cessation \
  --outcomes incidence \
  --output-mode data
```

### Custom Mode (Simulation)

Runs a custom intervention simulation and saves simsets for subsequent batch extraction:

```bash
# Step 1: Simulate
docker run --rm \
  -v $(pwd)/simulations:/data:ro \
  -v $(pwd)/output:/output \
  -e LOCATION=C.12580 \
  -e SCENARIO_KEY=a50-o30-r40 \
  -e ADAP_LOSS=50 -e OAHS_LOSS=30 -e OTHER_LOSS=40 \
  -e OUTCOMES=incidence,suppression \
  -e STATISTICS=mean.and.interval \
  -e FACETS=none,age \
  -e OUTPUT_DIR=/output \
  ghcr.io/ncsizemore/jheem-ryan-white-model:2.2.1 custom

# Step 2: Extract JSON from saved simsets
docker run --rm \
  -v $(pwd)/output/simulations:/app/simulations:ro \
  -v $(pwd)/output:/output \
  ghcr.io/ncsizemore/jheem-ryan-white-model:2.2.1 batch \
  --city C.12580 --scenarios a50-o30-r40 \
  --outcomes incidence,suppression \
  --statistics mean.and.interval --facets none,age \
  --output-dir /output/C.12580/a50-o30-r40 \
  --output-mode data --json-only
```

### Test Workspace

```bash
docker run --rm ghcr.io/ncsizemore/jheem-ryan-white-model:2.2.1 test-workspace
```

## Architecture

```
ghcr.io/ncsizemore/jheem-base:1.2.0           (shared R environment, jheem2 1.6.2)
  └── ghcr.io/ncsizemore/jheem-ryan-white-model:2.2.1  (this container)
```

### What's in this container

| File | Purpose |
|------|---------|
| `ryan_white_workspace.RData` | Prebuilt workspace (RW.SPECIFICATION, RW.DATA.MANAGER) |

Everything else (R packages, batch_plot_generator.R, custom_simulation.R, entrypoint) comes from jheem-base.

### Prebuilt Workspace (Tech Debt)

The workspace is copied from v2.1.0 rather than built fresh, because the runtime jheem2 (1.6.2) is too old for the current `jheem_analyses` workspace creation API. The workspace is just serialized state — the diffeq behavior comes from the installed jheem2 package. See Dockerfile comments for details and instructions to re-enable fresh builds.

### Version Matching

This container uses jheem-base v1.2.0 which pins jheem2 to 1.6.2. This matches the version used to generate the MSA simsets (`ryan-white-msa-v1.0.0`). **Do not update the base version without verifying jheem2 version compatibility with the simsets.** See jheem-base README for details.

## Building

```bash
docker build -t jheem-ryan-white-model .
```

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `BASE_VERSION` | `1.2.0` | jheem-base image version (source of truth — workflow defers to this) |

## Related Repositories

| Repository | Purpose |
|------------|---------|
| [jheem-base](https://github.com/ncsizemore/jheem-base) | Shared base image |
| [jheem-backend](https://github.com/ncsizemore/jheem-backend) | Workflows that run this container |
| [jheem-portal](https://github.com/ncsizemore/jheem-portal) | Frontend that displays generated data |
