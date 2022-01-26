# TODOs
- server: check the SLA, if the 2nd failure of a checker occurs more than SLA-days after the 1st failure, we need to escallate that more (e.g. a different Slack notification)
- server: show metrics over how often checks fail, and how fast failures get resolved
- add CLI options to the dbl-checker so it can run locally without sending checks to remote (or offer a sandbox on remote)
- add a config file, that is not the initializer (since it is unexpected, that we cannot reference anything from the app in the initializer) -> this config is just for the "cron" process, and has to contain: slack webhook url (optional), app_version, dbl-checker-api-key (optional), adapters
- update readme
