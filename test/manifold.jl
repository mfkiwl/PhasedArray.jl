@testset "Ideal manifold" begin
    f_0 = 1575420e3
    c₀ = 299_792_458
    λ = c₀ / f_0
    ant_pos = λ / 4 * [1 -1 1 -1; 1 1 -1 -1; 0 0 0 0];
    steer_vec = @inferred PhasedArray.manifold(ant_pos, f_0)

    @test @inferred(steer_vec(SVector(0,0,1))) ≈ [1, 1, 1, 1]
    @test @inferred(steer_vec(SVector(0,1,0))) ≈ [1im, 1im, -1im, -1im]
    @test @inferred(steer_vec(SVector(1,0,0))) ≈ [1im, -1im, 1im, -1im]
end

@testset "LUT manifold" begin
    λ = 0.1904
    ant_pos = λ / 4 * [1 -1 1 -1; 1 1 -1 -1; 0 0 0 0];
    num_ants = size(ant_pos, 2)
    # Simulated measured pattern
    antenna_gain = 2;
    sph2cart = CartesianFromSpherical()
    lut = [antenna_gain * cis(2 * π / λ * sph2cart(Spherical(1.0, θ * π / 180, π / 2 - ϕ * π / 180))' * ant_pos[:,ant]) for ant = 1:num_ants, ϕ=0:90, θ=0:359]
    steer_vec = @inferred PhasedArray.manifold(lut, Interpolations.Constant(), π / 2)
    @test norm(@inferred(steer_vec(SphericalFromCartesian()(SVector(1, 1, 1))))) ≈ sqrt(num_ants)
    @test @inferred(steer_vec(SphericalFromCartesian()(SVector(0,0,1)))) ≈ [1, 1, 1, 1]
    @test @inferred(steer_vec(SphericalFromCartesian()(SVector(0,1,0)))) ≈ [1im, 1im, -1im, -1im]
    @test @inferred(steer_vec(SphericalFromCartesian()(SVector(1,0,0)))) ≈ [1im, -1im, 1im, -1im]
end

@testset "LUT manifold interpolated" begin
    λ = 0.1904
    ant_pos = λ / 4 * [1 -1 1 -1; 1 1 -1 -1; 0 0 0 0];
    num_ants = size(ant_pos, 2)

    # Simulated measured pattern
    antenna_gain = 2;
    sph2cart = CartesianFromSpherical()
    lut = [antenna_gain * cis(2 * π / λ * sph2cart(Spherical(1.0, θ * π / 180, π / 2 - ϕ * π / 180))' * ant_pos[:,ant]) for ant = 1:num_ants, ϕ=0:90, θ=0:359]
    steer_vec = @inferred PhasedArray.manifold(lut, Interpolations.Linear(), π / 2)

    @test isapprox(norm(@inferred(steer_vec(SphericalFromCartesian()(SVector(1, 1, 1))))), sqrt(num_ants); rtol = 1e-4)
    @test @inferred(steer_vec(SphericalFromCartesian()(SVector(0,0,1)))) ≈ [1, 1, 1, 1]
    @test @inferred(steer_vec(SphericalFromCartesian()(SVector(0,1,0)))) ≈ [1im, 1im, -1im, -1im]
    @test @inferred(steer_vec(SphericalFromCartesian()(SVector(1,0,0)))) ≈ [1im, -1im, 1im, -1im]
end

@testset "Example LUT manifold" begin
    num_ants = size(EXAMPLE_LUT, 1)
    steer_vec = @inferred PhasedArray.manifold(EXAMPLE_LUT)
    @test norm(@inferred(steer_vec(SphericalFromCartesian()(SVector(0,0,1))))) < sqrt(num_ants)
end

@testset "LUT expansion" begin
    lut = randn(4, 10, 10)
    lut_expanded = PhasedArray.expand(lut, 2)
    @test size(lut_expanded) == (4, 14, 14)
    @test lut_expanded[:,:,1] == lut_expanded[:,:,11]
    @test lut_expanded[:,:,2] == lut_expanded[:,:,12]
    @test lut_expanded[:,:,3] == lut_expanded[:,:,13]
    @test lut_expanded[:,:,4] == lut_expanded[:,:,14]
    @test lut_expanded[:,1,3:12] == circshift(lut_expanded[:,5,3:12], (0,5))
    @test lut_expanded[:,2,3:12] == circshift(lut_expanded[:,4,3:12], (0,5))
    @test lut_expanded[:,14,3:12] == circshift(lut_expanded[:,10,3:12], (0,5))
    @test lut_expanded[:,13,3:12] == circshift(lut_expanded[:,11,3:12], (0,5))

    @test PhasedArray.calc_expansion_length(Constant()) == 1
    @test PhasedArray.calc_expansion_length(Constant()) == 1
    @test PhasedArray.calc_expansion_length(Quadratic(Reflect(OnCell()))) == 7
end
