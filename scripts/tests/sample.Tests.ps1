. "${SCRIPTROOT}/libs/sample.ps1"

describe "sampleTest" {
    it "sampleTest" {
        $result = Get-Greeting "World"
        $result | Should -Be "Hello, World!"
    }
}
