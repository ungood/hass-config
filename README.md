# hass-config

My Home Assistant configuration

## Authorization

```bash
cp .env.template .env
# Modify .env appropriately

direnv allow

# Test the connection (note that hass-cli info hits a deprecated API and therefore doesn't work)
hass-cli config release
```

## References

- [Home Assistant Documentation](https://www.home-assistant.io/)
- [Home Assistant Community](https://community.home-assistant.io/)
- [Home Assistant GitHub](https://github.com/home-assistant/home-assistant)
- Example Configs:
  - [Frenck](https://github.com/frenck/home-assistant-config)
