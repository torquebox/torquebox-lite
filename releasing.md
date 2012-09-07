# Releasing

Substitute ${release_version} for the version being released and
${dev_version} for the next development version - ie
${release_version} of 0.1.0 and ${dev_version} of 0.1.1-SNAPSHOT.

    mvn -B versions:set -DnewVersion=${release_version}
    mvn clean
    mvn install

Do some manual testing of the gem in
`gems/torquebox-lite/target/torquebox-lite-${release_version}`. After
everything's ok, finish the release.

    gem push gems/torquebox-lite/target/torquebox-lite-${release_version}.gem
    mvn -B versions:set -DnewVersion=${dev_version}
    find . -name "pom.xml.versionsBackup" | xargs rm
