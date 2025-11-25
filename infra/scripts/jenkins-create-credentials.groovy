import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.system.SystemCredentialsProvider

def store = SystemCredentialsProvider.getInstance().getStore()
def domain = Domain.global()

def addOrUpdateUsernamePassword(String id, String description, String username, String password) {
    def existing = store.getCredentials(domain).find { it.id == id }
    def creds = new UsernamePasswordCredentialsImpl(CredentialsScope.GLOBAL, id, description, username, password)
    if (existing) {
        store.updateCredentials(domain, existing, creds)
        println("Updated credentials '${id}'")
    } else {
        store.addCredentials(domain, creds)
        println("Created credentials '${id}'")
    }
}

addOrUpdateUsernamePassword(
        "nexus-admin",
        "Nexus account for Gradle publishing",
        System.getenv("NEXUS_USER") ?: "admin",
        System.getenv("NEXUS_PASS") ?: "replace-me"
)

addOrUpdateUsernamePassword(
        "dockerhub-creds",
        "Docker Hub account for pushing container images",
        System.getenv("DOCKER_HUB_USER") ?: "replace-me",
        System.getenv("DOCKER_HUB_TOKEN") ?: "replace-me"
)

