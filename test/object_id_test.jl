# Testing ObjectId

function single_id_test()
    id1 = SingleId(:id1, [1, 2])
    @test id1.index == [1,2]
    @test has_index(id1)

    id11 = SingleId(:id1, [1, 2]);
    @test isequal(id1, id11)

    id2 = SingleId(:id2, 3)
    @test id2.index == [3]

    id3 = SingleId(:id3);
    @test isempty(id3.index)
    @test !has_index(id3)
    @test isequal(id3, SingleId(:id3))

    @test isequal([id1, id2], [id1, id2])
    @test !isequal([id1, id1], [id2, id1])
    @test !isequal([id1, id2], [id1])

    return true
end

struct TestObj4 <: ModelObject
    objId :: ObjectId
end

function object_id_test()
    # Simplest case
    id1 = SingleId(:id1);
    o1 = ObjectId(id1);
    @test !ModelParams.has_parent(o1)
    @test isequal(ModelParams.make_string(id1), "id1")

    # Index, no parents
    o2 = ObjectId(:id2, 2)
    @test ModelParams.own_index(o2) == [2]
    pId = ModelParams.convert_to_parent_id(o2);
    @test isa(pId, ModelParams.ParentId)

    # Has id1 as parent
    o3 = ObjectId(:id3, 2, o1);
    p3 = ModelParams.get_parent_id(o3);
    @test ModelParams.is_parent_of(p3, o3)
    pId = ModelParams.convert_to_parent_id(o3);
    @test length(pId.ids) == 2
    @test isequal(ModelParams.make_string(o3), "id1 > id3[2]")

    o4 = ObjectId(:id4, pId);
    pId4 = ModelParams.convert_to_parent_id(o4);
    @test isequal(pId4.ids, [id1, SingleId(:id3, 2), SingleId(:id4)])

    obj4 = TestObj4(o4);
    childId = ModelParams.make_child_id(obj4, :child);
    @test isequal(childId.ids[end],  SingleId(:child))
    @test isequal(pId4, ModelParams.get_parent_id(childId))

    # Check `isequal` when "depth" of `ObjectId`s is different
    @test !isequal(obj4.objId, childId)

    return true
end

@testset "OjbectId" begin
    @test single_id_test()
    @test object_id_test()
end

# -----------
