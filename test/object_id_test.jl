# Testing ObjectId

struct TestObj4 <: ModelObject
    objId :: ObjectId
end

function single_id_test()
    @testset "SingleId" begin
        id1 = SingleId(:id1, [1, 2])
        show(id1);
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

        id4 = SingleId(:id4);
        s4 = ModelParams.make_string(id4);
        @test isequal(s4, "id4")
        id4a = ModelParams.make_single_id(s4);
        @test isequal(id4, id4a)

        id5 = SingleId(:id5, [4, 2]);
        s5 = ModelParams.make_string(id5);
        id5a = ModelParams.make_single_id(s5);
        @test isequal(id5, id5a)

        id6 = SingleId(:id6, 4)
        s6 = ModelParams.make_string(id6);
        id6a = ModelParams.make_single_id(s6);
        @test isequal(id6, id6a)
    end
end


function object_id_test()
    @testset "ObjectId" begin
        # Simplest case
        id1 = SingleId(:id1);
        o1 = ObjectId(id1);
        @test !ModelParams.has_parent(o1)
        s1 = make_string(id1);
        @test isequal(s1, "id1")
        o1a = make_object_id(s1)
        @test isequal(o1, o1a)

        # Index, no parents
        o2 = ObjectId(:id2, 2)
        show(o2);
        @test ModelParams.own_index(o2) == [2]
        pId = ModelParams.convert_to_parent_id(o2);
        @test isa(pId, ModelParams.ParentId)
        @test ModelParams.own_name(o2) == :id2

        # Has id1 as parent
        o3 = ObjectId(:id3, 2, o1);
        show(o3)
        p3 = ModelParams.get_parent_id(o3);
        @test ModelParams.is_parent_of(p3, o3)
        pId = ModelParams.convert_to_parent_id(o3);
        @test length(pId.ids) == 2
        s3 = ModelParams.make_string(o3);
        @test isequal(s3, "id1 > id3[2]")
        o3a = make_object_id(s3)
        @test isequal(o3, o3a)

        o4 = ObjectId(:id4, pId);
        pId4 = ModelParams.convert_to_parent_id(o4);
        @test isequal(pId4.ids, [id1, SingleId(:id3, 2), SingleId(:id4)])

        obj4 = TestObj4(o4);
        childId = ModelParams.make_child_id(obj4, :child);
        @test isequal(childId.ids[end],  SingleId(:child))
        @test isequal(pId4, ModelParams.get_parent_id(childId))
        @test isequal(ModelParams.own_name(obj4), :id4)

        # Check `isequal` when "depth" of `ObjectId`s is different
        @test !isequal(obj4.objId, childId)
    end
end

@testset "ObjectId" begin
    single_id_test()
    object_id_test()
end

# -----------
