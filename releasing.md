# Releasing

Make sure CHANGELOG.md is up-to-date.

Substitute ${release_version} for the version being released and
${dev_version} for the next development version - ie
${release_version} of 0.1.0 and ${dev_version} of 0.1.1-SNAPSHOT.

    mvn -B versions:set -DnewVersion=${release_version}
    find . -name "pom.xml.versionsBackup" | xargs rm
    mvn clean
    mvn install

Do some manual testing of the gem in
`gems/torquebox-lite/target/torquebox-lite-${release_version}`. After
everything's ok, finish the release.

    gem push gems/torquebox-lite/target/torquebox-lite-${release_version}.gem

Commit all pom.xml changes to git then tag the release

    git commit -am "Release version ${release_version}"
    git push
    git tag ${release_version}
    git push --tags

Bump the versions for next release

    mvn -B versions:set -DnewVersion=${dev_version}
    find . -name "pom.xml.versionsBackup" | xargs rm
    git commit -am "Prepare for next development iteration"
    git push
