# Corbench
Benchmarking tool for cortex

Refer to [corbench/README.md](corbench/README.md)

## Tool Usage

**Available Commands:**
    * To start benchmark: `/corbench <cortex-tag>`
    * To stop benchmark: `/corbench cancel`
    * To print help: `/corbench help`

    **Cortex tag format:** `master-<commit-hash>` (e.g., `master-6b3bd7b`) This will be the version of cortex that your PR will be benchmarked against
    * MAKE SURE TO PICK AN EXISTING CORTEX TAG FROM BELOW LINK, OR DEPLOYMENT WILL BE STUCK AND YOU WILL HAVE TO CANCEL AND START AGAIN
    * Check what cortex tags are avaliable to choose from at https://hub.docker.com/r/cortexproject/cortex/tags

    **Examples:**
    * `/corbench master-6b3bd7b`
    * `/corbench master-9861229`