# =============================================================================
# JHEEM Ryan White Model (MSA + AJPH)
# Thin wrapper around jheem-base - only adds workspace creation
# =============================================================================
ARG BASE_VERSION=1.0.0
FROM ghcr.io/ncsizemore/jheem-base:${BASE_VERSION} AS base

# --- Build workspace ---
FROM base AS workspace-builder

ARG JHEEM_ANALYSES_COMMIT=fc3fe1d2d5f859b322414da8b11f0182e635993b
WORKDIR /app

# Clone jheem_analyses at specific commit
RUN git clone https://github.com/tfojo1/jheem_analyses.git && \
    cd jheem_analyses && git checkout ${JHEEM_ANALYSES_COMMIT}

# Create symlink so ../jheem_analyses paths resolve from /app
# This handles all the relative path assumptions in jheem_analyses code
RUN ln -s /app/jheem_analyses /jheem_analyses

# Download cached data files from OneDrive using metadata
RUN cd jheem_analyses && mkdir -p cached && \
    R --slave -e "load('commoncode/data_manager_cache_metadata.Rdata'); \
    for(f in names(cache.metadata)) cat('wget -O cached/',f,' \"',cache.metadata[[f]][['onedrive.link']],'\"\n',sep='')" \
    | bash

# Copy google_mobility_data (not in official cache yet)
COPY cached/google_mobility_data.Rdata jheem_analyses/cached/
COPY create_ryan_white_workspace.R ./

# Apply path fixes for container environment
# The symlink makes ../jheem_analyses work, so we patch to that path
RUN sed -i 's/USE.JHEEM2.PACKAGE = F/USE.JHEEM2.PACKAGE = T/' \
        jheem_analyses/use_jheem2_package_setting.R && \
    sed -i 's|../../cached/ryan.white.data.manager.rdata|../jheem_analyses/cached/ryan.white.data.manager.rdata|' \
        jheem_analyses/applications/ryan_white/ryan_white_specification.R

# Create workspace - run from /app, use ../jheem_analyses (via symlink)
RUN Rscript create_ryan_white_workspace.R ryan_white_workspace.RData ../jheem_analyses && \
    test -f ryan_white_workspace.RData

# --- Final image ---
FROM base AS final

LABEL org.opencontainers.image.source="https://github.com/ncsizemore/jheem-ryan-white-container"
LABEL org.opencontainers.image.description="JHEEM Ryan White model container (MSA + AJPH)"

COPY --from=workspace-builder /app/ryan_white_workspace.RData ./

# Verify workspace
RUN R --slave -e "load('ryan_white_workspace.RData'); \
    cat('Objects:', length(ls()), '\n'); \
    stopifnot(exists('RW.SPECIFICATION')); \
    stopifnot(exists('RW.DATA.MANAGER')); \
    cat('Workspace verified\n')"

ENTRYPOINT ["./container_entrypoint.sh"]
CMD ["batch"]
