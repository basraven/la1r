---
trigger: always_on
globs: kubernetes
---

# Kubectl usage
1. Always write any kubernetes change as a yaml file, NEVER do kubectl patch. kubectl rollout restart is allowed. This way we make sure things can be replayed.

# Folder structure
1. Only use /kubernetes in this project, never look at .deprecated or kubernetes-backup or kubernetes-manual


# Misc
Always prepand your reply with 🛞 (can be multiple icons for multiple rules) if you read and understood these rules. Ask if rules are not clear so we can improve rules.