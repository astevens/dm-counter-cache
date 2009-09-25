require 'spec_helper'

describe DataMapper::CounterCacheable do
  before :all do
    class Post
      include DataMapper::Resource

      property :id, Serial
      property :comments_count, Integer, :default => 0
      has n, :comments
    end
    
    class Comment
      include DataMapper::Resource
      include DataMapper::CounterCacheable  

      property :id, Serial
      belongs_to :post, :counter_cache => true
    end
    
    class User
      include DataMapper::Resource

      property :id, Serial
      property :groups_count, Integer, :default => 0      

      has n, :group_memberships
      has n, :groups, :through => :group_memberships, :via => :group
    end
    
    class Group
      include DataMapper::Resource

      property :id, Serial
      property :members_count, Integer, :default => 0
      has n, :group_memberships
      has n, :members, "User", :through => :group_memberships, :via => :member
    end

    class GroupMembership
      include DataMapper::Resource
      include DataMapper::CounterCacheable

      property :id, Serial

      belongs_to :group, :counter_cache => :members_count
      belongs_to :member, :model => "User", :child_key => [:user_id], :counter_cache => :groups_count
    end    
  end

  before(:each) do
    DataMapper.auto_migrate!
    @post = Post.create
    @user = User.create
    @group = Group.create
  end

  it "should increment comments_count" do
    @post.comments.create
    @post.reload.comments_count.should == 1
    
    @user.group_memberships.create(:group => @group)
    @user.reload.groups_count.should == 1
    @group.reload.members_count.should == 1
  end

  it "should decrement comments_count" do
    comment1 = @post.comments.create    
    comment2 = @post.comments.create
    comment2.destroy
    @post.reload.comments_count.should == 1
  end
  
  it "should increment groups_count and members_count" do
    gm1 = @user.group_memberships.create(:group => @group)
    @user.reload.groups_count.should == 1
    @group.reload.members_count.should == 1    
  end
  
  it "should increment/decrement groups_count and members_count" do
    gm1 = @user.group_memberships.create(:group => @group)
    gm2 = @user.group_memberships.create(:group => @group)
    gm2.destroy
    @user.reload.groups_count.should == 1
    @group.reload.members_count.should == 1    
  end
  
  it "should allow normal belongs_to behavior" do
    @post.comments.create
    comment1 = Comment.first
    comment1.post.should == @post
  end
  
end
