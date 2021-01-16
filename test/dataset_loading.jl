@testset "dataset_loading" begin
    @test load_station_metadata() isa DataFrame
    @test load_countries_metadata() isa DataFrame
    @test load_inventories() isa DataFrame
end
