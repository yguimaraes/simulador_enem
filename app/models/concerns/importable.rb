#encoding: utf-8
require 'active_support/concern'

class String

  def only_alphanumeric
    self.gsub(/[^0-9a-z]/i, '')
  end

  def underscore
    self.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
  end

  def without_accent
    self.tr(
        "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
        "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz")
  end
end

module Importable
  extend ActiveSupport::Concern

  SEMESTER = "2015.1"

  def get_mapping_branch
    @mapping_course ||= ZndbxNewAesa.get_mapping_from_file("de_para_unidades.csv","branch_name","branch_uid")
  end

  def get_mapping_course
    @mapping_course ||= ZndbxNewAesa.get_mapping_from_file("de_para_cursos.csv","de","para")
  end

  def get_assessment_uid_base(name_course )
    treated_name_course = name_course.without_accent.downcase.only_alphanumeric
    if get_mapping_course.keys.include? treated_name_course
      return get_mapping_course[treated_name_course]
    else
      ac = AcademicCourse.find_by_course_name(name_course)
      if ac
        return ac.assessment_uid
      else
        raise "Course #{name_course} not found in mapping"
      end
    end
  end

  def branch_name_base(name)
    treated_name = name.without_accent.downcase.only_alphanumeric
    @branch_name ||=
        if get_mapping_branch.keys.include? treated_name
          @branch_uid = get_mapping_branch[treated_name]
          Branch.find_by_branch_uid(@branch_uid).branch_name
        else
          if Branch.find_by_branch_name(name)
            name
          else
            raise "Branch #{name} not found in mapping"
          end
        end
    @branch_name
  end

  def get_new_physical_branch_uid(branch_uid)
    if presencial?
      branch_uid
    else
      prefix = physical_branch_prefix
      get_new_uid(prefix, PhysicalBranch.where("physical_branch_uid like ?", prefix + '%').pluck(:physical_branch_uid).max,4)
    end
  end

  def get_new_branch_course_uid
    prefix = branch_course_prefix
    get_new_uid(prefix, BranchCourse.where("branch_course_uid like ?", prefix + '%').pluck(:branch_course_uid).max,5)
  end

  def get_new_course_uid
    prefix = course_prefix
    get_new_uid(prefix, AcademicCourse.pluck(:course_uid).max,3)
  end

  def get_new_uid(prefix, last_used , size = 2 )
    prefix + (( last_used || prefix + "0"*size)[-size..-1].to_i + 1).to_s.rjust(size, "0")
  end


  def get_new_bu_uid
    prefix = bu_prefix
    get_new_uid(prefix, BusinessUnit.pluck(:bu_uid).max)
  end

  def get_new_macro_branch_uid
    prefix = macro_branch_prefix
    get_new_uid(prefix, MacroBranch.where("macro_branch_uid like ?", prefix + '%').pluck(:macro_branch_uid).max)
  end


  def get_new_branch_uid
    prefix = branch_prefix
    get_new_uid(prefix, Branch.where("branch_uid like ?", prefix + '%').pluck(:branch_uid).max,3)
  end


  def create_branch_course(course, physical_branch, branch,manager, client_uid = "KRTN")
    enrolment = get_enrolment(manager)
    branch_course = BranchCourse.find_or_initialize_by(branch_name: branch_name_in_branch_course,course_name: course.course_name,branch_uid: branch.branch_uid, client_uid: client_uid)

    if branch_course.new_record?
      branch_course.branch_course_uid = get_new_branch_course_uid
      branch_course.physical_branch_uid = physical_branch.physical_branch_uid
      branch_course.physical_branch_name = physical_branch_name
      branch_course.course_uid = course.course_uid
      branch_course.manager_enrolment = enrolment
      branch_course.marketing_target = 0.0
      branch_course.save!
      puts "Created BranchCourse with uid #{branch_course.branch_course_uid} "
    end
    return branch_course
  end

  def create_branch(macro_branch, manager, client_uid = "KRTN")

    branch = Branch.find_or_initialize_by(branch_name: branch_name,macro_branch_uid: macro_branch.macro_branch_uid, client_uid: client_uid)

    if branch.new_record?
      branch.branch_uid = get_new_branch_uid
      branch.manager_enrolment = get_enrolment(manager)
      branch.save!
      puts "Created Branch with name #{branch.branch_name} "
    end
    return branch
  end

  def create_physical_branch(branch,bu, client_uid = "KRTN")
    physical_branch = PhysicalBranch.find_or_initialize_by(physical_branch_name: physical_branch_name, bu_uid: bu.bu_uid, client_uid: client_uid)

    if physical_branch.new_record?
      #raise Exception.new("Cannot create physical_branch #{physical_branch_name} for bu #{bu.bu_uid}")
      physical_branch.physical_branch_uid = get_new_physical_branch_uid(branch.branch_uid)
      physical_branch.save!
      puts "Created PhysicalBranch with name #{physical_branch.physical_branch_name} "
    end
    return physical_branch
  end


  def create_macro_branch(bu,manager, client_uid = "KRTN")

    macro_branch = MacroBranch.find_or_initialize_by(macro_branch_name: macro_branch_name,bu_uid: bu.bu_uid, client_uid: client_uid)

    if macro_branch.new_record?
      #raise Exception.new("Cannot create macro_branch #{macro_branch_name}")
      macro_branch.macro_branch_uid = get_new_macro_branch_uid
      enrolment = get_enrolment(manager)
      macro_branch.manager_enrolment = enrolment
      macro_branch.save!
      puts "Created MacroBranch with name #{macro_branch.macro_branch_name} "
    end

    return macro_branch
  end


  def create_org_permission(user, object , manager_tag = nil)
    op = OrgPermission.find_or_initialize_by(manager_enrolment: user.enrolment,type_permission: object.type_permission, org_uid: object.org_uid)
    if op.new_record?
      op.type_permission = object.type_permission
      op.save!
      puts "Created OrgPermission for #{op.org_uid} and #{op.manager_enrolment} "
    end

    if manager_tag
      op.manager_tag = manager_tag
      op.save!
    end
    OrgPermission.check_correct_levels(user)

    return op
  end



  def create_bu(manager)
    bu = BusinessUnit.find_or_initialize_by(bu_name: bu_name)
    if bu.new_record?
      raise Exception.new("Cannot create BU at the moment.")
      enrolment = get_enrolment(manager)
      bu.bu_uid = self.get_new_bu_uid
      bu.manager_enrolment = enrolment
      bu.save!
      puts "Created BU with name #{bu.bu_name} "
    end
    return bu
  end

  def create_course(assessment_uid)
    ac = AcademicCourse.find_or_initialize_by(course_name: course_name,assessment_uid: assessment_uid)
    if ac.new_record?
      ac.course_uid = get_new_course_uid
      ac.save!
      puts "Created course with name #{ac.course_name} "
    end
    return ac
  end

  def create_study_class(branch_course, manager, class_semester )
    enrolment = get_enrolment(manager)
    study_class = StudyClass.find_or_initialize_by(study_class_name: study_class_name)

    if branch_course
      study_class.branch_uid = branch_course.branch_uid
      study_class.course_uid = branch_course.course_uid
      study_class.branch_course_uid = branch_course.branch_course_uid
    end

    if enrolment
      study_class.manager_enrolment = enrolment
    end

    study_class.class_period = class_semester
    study_class.save!
    puts "Created StudyClass with name #{study_class.study_class_name} "

    return study_class
  end

  def create_structure_and_permissions(sc_professor,bc_professor, branch_director,class_semester)
    bu               = create_bu(nil )
    macro_branch     = create_macro_branch(bu,nil)
    branch           = create_branch(macro_branch,nil)
    physical_branch  = create_physical_branch(branch,bu)
    course           = get_course
    branch_course    = create_branch_course(course,physical_branch,branch,bc_professor)
    study_class      = create_study_class(branch_course,sc_professor, class_semester)

    create_org_permission(sc_professor,study_class,1) if sc_professor
    create_org_permission(bc_professor,branch_course,1) if bc_professor
    create_org_permission(branch_director,branch,1) if branch_director
    study_class
  end

  def get_enrolment(manager)
    if manager
      manager.enrolment
    else
      "N/A"
    end
  end

  def run_action!
    if ( run_tag == 0  )
      begin
        do_action!
        self.run_tag = 1
        self.error_message = nil
        self.save!
      rescue => e
        self.error_message = e.message
        self.save!
        false
      end
    else
      false
    end
  end


  module ClassMethods

    def get_map_mapping_from_file(file,prim_key,from, to)
      mapping = {}
      CSV.foreach(File.join(Rails.root, "db", "import", "zndbx",file), :headers => true, :col_sep => ";" ) do |row|
        row_h = row_to_hash_handled(row,true)
        mapping[row_h[prim_key]] ||= {}
        key = row_h[from].without_accent.downcase.only_alphanumeric
        mapping[row_h[prim_key]][key] = row_h[to]
      end
      mapping
    end

    def get_mapping_from_file(file,from, to)
      mapping = {}
      CSV.foreach(File.join(Rails.root, "db", "import", "zndbx",file), :headers => true, :col_sep => ";" ) do |row|
        row_h = row_to_hash_handled(row,true)
        key = row_h[from].without_accent.downcase.only_alphanumeric
        mapping[key] = row_h[to]
      end
      mapping
    end

    def handle_column_name(column, to_underscore = true )
      column ||= "_"
      str = column.gsub(/[-]/, '').without_accent
      str = str.underscore if to_underscore
      str.gsub(/[ ]/, '_').gsub(/[^0-9a-z_]/i, '')
    end

    def row_to_hash_handled(row, to_underscore)
      row_h = {}
      row.each do |k,v|
        if !row_h.include? k
          if (true if Float(k) rescue false)
            row_h["q" + k] = v
          else
            row_h[k] = v
          end

        else
          n = 1
          while row_h.include?((k || "") + n.to_s)
            n += 1
          end
          row_h[(k || "") +n.to_s] = v
        end
      end
      Hash[row_h.map{|key,arg| [handle_column_name(key, to_underscore), arg] }]
    end

    def create_object(hsh)
      class_name = name
      clazz = class_name.constantize
      clazz.new(hsh.slice(*hsh.keys.map {|key, args| key}))
    end

    def import_kroton_data(file, col_sep, to_underscore = true, quote_char =  "ß", encoding = 'utf-8')

      count = 0
      import_data(file, col_sep , quote_char, encoding) do  |row|
        row_h = row_to_hash_handled(row, to_underscore)
        object = create_object(row_h)
        count += save_object(object)
      end

      puts "#{count} successfully created"
    end

    def save_object(object)
      if object.save
        1
      else
        puts "#{object.to_param} #{name} not created!\n"
        0
      end
    end

    def save_object_with_error(object)
      if object.save
        1
      else
        raise "#{object.to_param} #{name} not created!\n"
        0
      end
    end

    def import_data(file, col_sep, quote_char, encoding )

      count_total = 0
      puts "importing #{name}"

      CSV.foreach(file, :headers => true, :col_sep => col_sep, :quote_char => quote_char, :encoding => encoding ) do |row|
        yield row
        count_total += 1
        puts "#{count_total} imported" if count_total % 200 == 0
      end

      puts "total #{count_total} #{name} .\n"
    end

    def import_raw_data(file,client_uid = "KRTN")
      count = 0
      import_data(file, ";", '"', 'utf-8') do |row|
        begin
          row_h = row.to_hash
          object = create_object(row_h)
          count += save_object_with_error(object)
        rescue => e
          ErrorMessage.create(:error_message => e.message,
                              :class_name => name,
                              :obj_id => object && object.id,
                              :obj_params => object && object.attributes,
                              :client_uid => client_uid)
        end

      end
      puts "#{count} successfully created"
    end

  end

end