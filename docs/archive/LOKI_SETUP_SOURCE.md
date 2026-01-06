# Where Did the Loki Setup Come From?

## Grafazos Documentation

The [Grafazos documentation](https://octez.tezos.com/docs/grafazos-doc/) mentions:

> * `logs`: same as `basic` but also displaying node's logs (thanks to Loki and promtail)
> * `full`: same as `logs` but also displaying hardware metrics (thanks to netdata)

**But it doesn't provide:**
- ❌ Loki installation instructions
- ❌ Promtail configuration
- ❌ Docker Compose setup
- ❌ How to connect Loki to Grafana

## Where the Setup Came From

The Loki/Promtail setup I created is based on:

### 1. Standard Loki/Promtail Setup
- **Official Loki docs**: https://grafana.com/docs/loki/latest/
- **Promtail docs**: https://grafana.com/docs/loki/latest/clients/promtail/
- Standard Docker Compose patterns for Loki + Promtail

### 2. Docker Log Collection Pattern
- Promtail uses Docker service discovery to collect logs
- Standard pattern: Mount Docker socket, scrape container logs
- Common configuration for Docker-based setups

### 3. Grafana Integration
- Standard Loki datasource setup in Grafana
- Standard UID-based datasource references
- Common Grafana dashboard import process

## What Was Created

I created a **standard Loki/Promtail setup** that:
1. ✅ Works with Docker containers (your Tezos node)
2. ✅ Collects logs from Tezos containers
3. ✅ Integrates with your existing Grafana setup
4. ✅ Matches what Grafazos dashboards expect

## Why This Setup Works

The Grafazos dashboards expect:
- Loki datasource in Grafana
- Logs labeled with `job="tezos-node"`
- Standard LogQL queries

Our setup provides exactly that:
- Promtail collects Docker logs
- Labels them with `job="tezos-node"`
- Loki stores them
- Grafana queries them

## References

**Official Documentation:**
- Loki: https://grafana.com/docs/loki/latest/
- Promtail: https://grafana.com/docs/loki/latest/clients/promtail/
- LogQL: https://grafana.com/docs/loki/latest/logql/

**Grafazos (mentions but doesn't explain):**
- https://octez.tezos.com/docs/grafazos-doc/

## Summary

- **Grafazos docs**: Mention Loki/promtail are needed ✅
- **Grafazos docs**: Don't explain how to set them up ❌
- **Our setup**: Standard Loki/Promtail configuration ✅
- **Our setup**: Works with Grafazos dashboards ✅

The setup is **standard industry practice** for Loki/Promtail, adapted to work with your Tezos Docker containers and Grafazos dashboards.
