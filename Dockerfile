# =============================================================================
# JHEEM Ryan White Model (MSA + AJPH)
# Thin wrapper around jheem-base - only adds workspace
# =============================================================================
ARG BASE_VERSION=1.2.0
FROM ghcr.io/ncsizemore/jheem-base:${BASE_VERSION} AS base

# -----------------------------------------------------------------------------
# TECH DEBT: Prebuilt workspace (March 2026)
#
# The workspace is copied from a previous container image (v2.1.0, built with
# jheem2 1.9.2) instead of being rebuilt, because the runtime jheem2 version
# (1.6.2, matching MSA simset generation) is too old for the current
# jheem_analyses workspace creation code.
#
# This is safe because the workspace is just serialized state (specification
# objects, constants, ontology mappings). The diffeq behavior that must match
# between calibration and intervention comes from the installed jheem2 package,
# not the workspace. The container entrypoint re-exports current package
# functions over any stale copies loaded from the workspace.
#
# To rebuild fresh: uncomment the workspace-builder stage below, update
# JHEEM_ANALYSES_COMMIT, and change COPY --from to workspace-builder. Requires
# jheem2 version in jheem-base to be compatible with jheem_analyses API.
# -----------------------------------------------------------------------------

# --- Prebuilt workspace ---
FROM ghcr.io/ncsizemore/jheem-ryan-white-model:2.1.0 AS prebuilt-workspace

# --- Build workspace (currently unused - see tech debt note above) ---
# FROM base AS workspace-builder
#
# ARG JHEEM_ANALYSES_COMMIT=fc3fe1d2d5f859b322414da8b11f0182e635993b
# WORKDIR /app
#
# RUN git clone https://github.com/tfojo1/jheem_analyses.git && \
#     cd jheem_analyses && git checkout ${JHEEM_ANALYSES_COMMIT}
#
# RUN ln -s /app/jheem_analyses /jheem_analyses
#
# RUN cd jheem_analyses && mkdir -p cached && \
#     R --slave -e "load('commoncode/data_manager_cache_metadata.Rdata'); \
#     for(f in names(cache.metadata)) cat('wget -O cached/',f,' \"',cache.metadata[[f]][['onedrive.link']],'\"\n',sep='')" \
#     | bash
#
# COPY cached/google_mobility_data.Rdata jheem_analyses/cached/
# COPY create_ryan_white_workspace.R ./
#
# RUN sed -i 's/USE.JHEEM2.PACKAGE = F/USE.JHEEM2.PACKAGE = T/' \
#         jheem_analyses/use_jheem2_package_setting.R && \
#     sed -i 's|../../cached/ryan.white.data.manager.rdata|../jheem_analyses/cached/ryan.white.data.manager.rdata|' \
#         jheem_analyses/applications/ryan_white/ryan_white_specification.R
#
# RUN Rscript create_ryan_white_workspace.R ryan_white_workspace.RData ../jheem_analyses && \
#     test -f ryan_white_workspace.RData

# --- Final image ---
FROM base AS final

LABEL org.opencontainers.image.source="https://github.com/ncsizemore/jheem-ryan-white-container"
LABEL org.opencontainers.image.description="JHEEM Ryan White model container (MSA + AJPH)"

COPY --from=prebuilt-workspace /app/ryan_white_workspace.RData ./

# Verify workspace
RUN R --slave -e "load('ryan_white_workspace.RData'); \
    cat('Objects:', length(ls()), '\n'); \
    stopifnot(exists('RW.SPECIFICATION')); \
    stopifnot(exists('RW.DATA.MANAGER')); \
    cat('Workspace verified\n')"

ENTRYPOINT ["./container_entrypoint.sh"]
CMD ["batch"]
