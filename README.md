# JHEEM Ryan White Container

Docker container for the JHEEM Ryan White model (MSA + AJPH state analyses). Extends the shared [jheem-base](https://github.com/ncsizemore/jheem-base) image.

## Usage

The container is published to GitHub Container Registry:

```bash
docker pull ghcr.io/ncsizemore/jheem-ryan-white-model:latest
```

### Batch Mode (Data Generation)

```bash
docker run --rm ghcr.io/ncsizemore/jheem-ryan-white-model:2.0.0 batch \
  --city C.12580 \
  --scenarios cessation \
  --outcomes incidence \
  --output-mode data
```

### Test Workspace

```bash
docker run --rm ghcr.io/ncsizemore/jheem-ryan-white-model:2.0.0 test-workspace
```

## Architecture

This container uses a thin wrapper pattern:

```
ghcr.io/ncsizemore/jheem-base:1.0.0    (shared R environment, ~150 lines)
  └── ghcr.io/ncsizemore/jheem-ryan-white-model:2.0.0  (this container, ~50 lines)
```

### What's in this container

| File | Purpose |
|------|---------|
| `create_ryan_white_workspace.R` | Creates RW.SPECIFICATION and RW.DATA.MANAGER |
| `cached/google_mobility_data.Rdata` | Mobility data (not in official cache yet) |

Everything else (R packages, batch_plot_generator.R, entrypoint) comes from jheem-base.

## Building

```bash
docker build -t jheem-ryan-white-model .
```

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `BASE_VERSION` | `1.0.0` | jheem-base image version |
| `JHEEM_ANALYSES_COMMIT` | `fc3fe1d...` | jheem_analyses git commit |

## Related Repositories

| Repository | Purpose |
|------------|---------|
| [jheem-base](https://github.com/ncsizemore/jheem-base) | Shared base image |
| [jheem-backend](https://github.com/ncsizemore/jheem-backend) | Workflows that run this container |
| [jheem-portal](https://github.com/ncsizemore/jheem-portal) | Frontend that displays generated data |
